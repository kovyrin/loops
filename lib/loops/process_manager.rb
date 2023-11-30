# frozen_string_literal: true

module Loops
  class ProcessManager # :nodoc:
    attr_reader :config, :logger, :worker_pools

    def initialize(config, logger)
      @config = {
        'poll_period' => 5,
        'wait_period' => 10,
        'workers_engine' => 'fork'
      }.merge(config)

      @logger = logger
      @worker_pools = {}
      @shutdown = false
    end

    def update_wait_period(period)
      return unless period

      config['wait_period'] = [config['wait_period'], period].max
    end

    def start_workers(name, number, &)
      raise ArgumentError, 'Need a worker block!' unless block_given?

      logger.debug("Creating a workers pool of #{number} workers for #{name} loop...")
      worker_pools[name] = Loops::WorkerPool.new(name, self, @config['workers_engine'], &)
      worker_pools[name].start_workers(number)
    end

    # Starts the workers monitoring loop and exits when all workers have shut down
    def monitor_workers
      setup_process_manager_signals
      logger.info('Starting workers monitoring code...')
      poll_period = config['poll_period']

      loop do
        logger.debug("Checking workers' health...")
        worker_pools.each_value do |pool|
          break if shutdown?

          pool.check_workers
        end
        break if shutdown?

        logger.debug("Sleeping for #{poll_period} seconds...")
        interruptible_sleep(poll_period)
      end
    ensure
      logger.info('Workers monitoring loop is finished, starting shutdown...')
      # Send out stop signals
      stop_workers

      # Wait for all the workers to stop or enforce shutdown after 10 seconds
      wait_period = config['wait_period']
      unless wait_for_workers(wait_period)
        logger.info(
          "Some workers are still alive after #{wait_period} seconds. Forcing them to stop..."
        )
        stop_workers(force: true)
        wait_for_workers(5)
      end
    end

    # Sleeps for a given number of seconds, but can be interrupted by a shutdown signal
    def interruptible_sleep(seconds)
      start_time = Time.now
      loop do
        elapsed = Time.now - start_time
        break if elapsed >= seconds || shutdown?

        sleep(0.1)
      end
    end

    # Sets up signal handlers for the process manager to avoid zombie process creation
    def setup_process_manager_signals
      trap('CHLD') { sleep(0.01) }
      trap('EXIT') { sleep(0.01) }
    end

    # Waits for all workers to shut down or until the given number of seconds passes
    # Returns true if all workers have shut down, false otherwise
    def wait_for_workers(seconds)
      seconds.times do
        logger.info("Shutting down... waiting for workers to stop (we have #{seconds} seconds)...")
        running_total = 0

        worker_pools.each do |_name, pool|
          running_total += pool.wait_workers
        end

        if running_total.zero?
          logger.info('All workers have shut down successfully')
          return true
        end

        logger.info("#{running_total} workers are still running! Sleeping for a second...")
        sleep(1)
      end

      false
    end

    # Sends out stop signals to all workers
    # If force is true, workers are killed immediately
    def stop_workers(force: false)
      # Set shutdown flag
      logger.info("Stopping workers#{force ? ' (forced)' : ''}...")

      # Termination loop
      worker_pools.each_value do |pool|
        pool.stop_workers(force:)
      end
    end

    def shutdown?
      @shutdown
    end

    def start_shutdown!
      Thread.new do
        logger.info('Starting shutdown (shutdown flag set)...')
      end
      @shutdown = true
    end
  end
end
