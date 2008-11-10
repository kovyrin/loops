require 'loops/worker'

class Loops::ProcessManager 
  attr_reader :logger
  
  def initialize(config, logger)
    @config = {
      'poll_period' => 1
    }.merge(config)
    
    @logger = logger
    @workers = {}
    @shutdown = false
  end
  
  def start_workers(name, number, &blk)
    raise "Need a worker block!" unless block_given?
    workers = @workers[name] = []

    logger.debug("Creating #{number} of #{name} workers...")
    number.times do |id|
      workers << start_worker(name, &blk)
    end
  end
  
  def start_worker(name, &blk)
    logger.debug("Creating worker #{name}...")
    Worker.new(name, logger, &blk)
  end
  
  def monitor_workers
    setup_signals
    
    logger.debug('Starting workers monitoring code...')
    until @shutdown do
      logger.debug('Checking workers\' health...')
    
      @workers.each do |name, pool|
        break if @shutdown
        logger.debug("Checking loop #{name} workers...")
        pool.each do |worker|
          next if worker.running? || worker.shutdown?
          logger.debug("Worker #{worker.name} is not running. Restart!")
          worker.run
        end
      end

      logger.debug("Sleeping for #{@config['poll_period']} seconds...")
      sleep(@config['poll_period']) unless @shutdown
    end
  rescue Interrupt
    logger.debug("Received an interrupt while sleeping, forcefully-stopping all loops")
    stop_workers!
  ensure
    wait_for_workers
  end
  
  def setup_signals
    # Zombie rippers
    trap('CHLD') {}
    trap('EXIT') {}
  end
  
  def wait_for_workers
    loop do
      logger.debug("Shutting down... waiting for workers to die...")
      running_total = 0

      @workers.each do |name, pool|
        running = 0
        pool.each do |worker|
          next unless worker.running?(false)
          running += 1
          logger.debug("Worker #{name} is still running (#{worker.pid})")
        end
        running_total += running
      end

      if running_total.zero?
        logger.debug("All workers are dead. Exiting...")
        break
      end
      
      logger.debug("#{running_total} workers are still running! Sleeping for 1 second...")
      sleep(1)
    end
  end
  
  def stop_workers(force = false)
    return if @shutdown && !force
    logger.debug("Stopping workers#{force ? '(forced)' : ''}...")
    @shutdown = true

    # Termination loop
    @workers.each do |name, pool|
      logger.debug("Stopping loop #{name} workers...")
      pool.each do |worker|
        next unless worker.running?(false)
        worker.stop(force)
      end
    end
  end
  
  def stop_workers!
    stop_workers(false)
    sleep(1)
    stop_workers(true)
  end
end
