require 'loops/worker'
require 'pp'

class Loops::ProcessManager 
  attr_reader :logger
  
  def initialize(config, logger)
    @config = {
      'poll_period' => 1
    }.merge(config)
    
    pp @config
    
    @logger = logger
    @workers = {}
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
    loop do
      logger.debug('Checking workers\' health...')
    
      @workers.each do |name, pool|
        logger.debug("Checking loop #{name} workers...")
        pool.each do |worker|
          next if worker.running?
          logger.debug("Worker #{worker.name} is not running. Restart!")
          worker.run
        end
      end

      logger.debug("Sleeping for #{@config['poll_period']} seconds...")
      sleep(@config['poll_period'])
    end
  rescue Interrupt
    logger.debug("Received an interrupt while sleeping, forcefully-stopping all loops")
    stop_workers!
  end
  
  def setup_signals
    # Zombie rippers
    trap('CHLD') {}
    trap('EXIT') {}
  end
  
  def stop_workers(force = false)
    logger.debug("Stopping workers#{force ? '(forced)' : ''}...")

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
