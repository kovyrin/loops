# frozen_string_literal: true

module Loops
  class Engine
    attr_reader :loops_config, :global_config

    def initialize
      load_config
    end

    #----------------------------------------------------------------------------------------------
    def load_config
      # load and parse with erb
      raw_config = File.read(Loops.config_file)
      erb_config = ERB.new(raw_config).result

      @config = YAML.load(erb_config)
      @loops_config = @config['loops']
      unless loops_config.is_a?(Hash)
        raise("No or invalid data in 'loops' section in '#{Loops.config_file}'! Expected a hash.")
      end

      global_user_config = @config['global'] || {}
      unless global_user_config.is_a?(Hash)
        raise("Invalid data in 'global' section in '#{Loops.config_file}'! Expected a hash.")
      end

      @global_config = {
        'poll_period' => 1,
        'workers_engine' => 'fork'
      }.merge(global_user_config)

      Loops.logger.default_logfile = global_config['logger'] || $stdout
      Loops.logger.colorful_logs = global_config['colorful_logs'] || global_config['colourful_logs']
    end

    #----------------------------------------------------------------------------------------------
    def start_loops!(loops_to_start = [])
      enabled_loops = []

      # Initialize process manager
      @pm = Loops::ProcessManager.new(global_config, Loops.logger)

      # Start all enabled loops
      loops_config.each do |name, loop_config|
        loop_config ||= {}

        # Do not load the loop if it is disabled
        next if loop_config['disabled']
        next if loop_config.key?('enabled') && !loop_config['enabled']

        # Skip the loop if we were given a specific list of loops and this one wasn't on the list
        next unless loops_to_start.empty? || loops_to_start.member?(name)

        # Load the class
        klass = load_loop_class(name, loop_config)
        next unless klass

        # Start the loop
        start_loop(name, klass, loop_config)
        enabled_loops << name
      end

      # Do not continue if there is nothing to run
      if enabled_loops.empty?
        puts 'WARNING: No loops to run! Exiting...'
        return
      end

      # Set up signals to shut down when received an external signal to stop
      setup_signals

      # Start process monitoring loop
      @pm.monitor_workers

      # Done, exiting now
      info 'Loops are stopped now!'
    end

    #-----------------------------------------------------------------------------------------------
    def debug_loop!(loop_name)
      @pm = Loops::ProcessManager.new(global_config, Loops.logger)
      loop_config = loops_config[loop_name] || {}

      # Adjust loop config values before starting it in debug mode
      loop_config['workers_number'] = 1
      loop_config['debug_loop'] = true

      # Load loop class
      unless (klass = load_loop_class(loop_name, loop_config))
        puts "Can't load loop class!"
        return false
      end

      # Start the loop
      start_loop(loop_name, klass, loop_config)
    end

    private

    # Proxy logger calls to the default loops logger
    %i[debug error fatal info warn].each do |meth_name|
      class_eval <<-EVAL, __FILE__, __LINE__ + 1
        def #{meth_name}(message)                                                 # def debug(message)
          Loops.logger.#{meth_name} "loops[RUNNER/\#{Process.pid}]: \#{message}"  #   Loops.logger.debug "loops[RUNNER/\#{Process.pid}]: \#{message}"
        end                                                                       # end
      EVAL
    end

    def load_loop_class(name, config)
      loop_name = config['loop_name'] || name

      klass_files = [Loops.loops_root + "#{loop_name}_loop.rb", "#{loop_name}_loop"]
      begin
        klass_file = klass_files.shift
        debug "Loading class file: #{klass_file}"
        require(klass_file)
      rescue LoadError
        retry unless klass_files.empty?
        error "Can't load the class file: #{klass_file}. Worker #{name} won't be started!"
        return false
      end

      klass_name = "#{loop_name}_loop".split('/').map do |x|
        x.capitalize.gsub(/_(.)/) { ::Regexp.last_match(1).upcase }
      end.join('::')

      klass = begin
        Object.const_get(klass_name)
      rescue StandardError
        nil
      end
      klass = klass_name.constantize if klass_name.respond_to?(:constantize) && !klass

      unless klass
        error "Can't find class: #{klass_name}. Worker #{name} won't be started!"
        return false
      end

      begin
        klass.check_dependencies
      rescue Exception => e
        error "Loop #{name} dependencies check failed: #{e} at #{e.backtrace.first}"
        return false
      end

      klass
    end

    def set_logger_level(logger, config)
      return unless config

      if config.is_a?(String)
        level = begin
          Logger::Severity.const_get(config.upcase)
        rescue StandardError
          nil
        end
        logger.level = level if level
      elsif config.is_a?(Integer)
        logger.level = config
      else
        raise "Invalid log level value: #{config.inspect}"
      end
    end

    def define_loop_proc(loop_name, loop_class, loop_config)
      proc do |worker|
        the_logger = if Loops.logger.is_a?(Loops::Logger) && global_config['workers_engine'] == 'fork'
                       # This is happening right after the fork, therefore no need for teardown at
                       # the end of the proc
                       Loops.logger.logfile = loop_config['logger'] if loop_config['logger']
                       Loops.logger
                     else
                       # for backwards compatibility and handling threading engine
                       create_logger(loop_name, loop_config)
                     end

        # Set logger level
        set_logger_level(the_logger, loop_config['log_level'])

        # Colorize logging?
        configured_colorful_logs = loop_config['colorful_logs'] || loop_config['colourful_logs']
        if the_logger.respond_to?(:colorful_logs=) && configured_colorful_logs
          the_logger.colorful_logs = configured_colorful_logs
        end

        debug "Instantiating loop class: #{loop_class}"
        the_loop = loop_class.new(worker, loop_name, loop_config)

        # Fix ActiveRecord connections after forking
        fix_ar_after_fork

        # Reseed the random number generator in case a loop calls srand or rand prior to forking
        srand

        debug "Starting the loop #{loop_name}!"
        the_loop.run
      end
    end

    def start_loop(name, klass, loop_config)
      info "Starting loop: #{name}"
      info " - config: #{loop_config.inspect}"

      begin
        if klass.respond_to?(:initialize_loop)
          debug 'Initializing loop'
          klass.initialize_loop(loop_config)
          debug 'Initialization successful'
        end
      rescue StandardError => e
        error("Initialization failed: #{e.message}\n  " + e.backtrace.join("\n  "))
        return
      end

      # Create loop proc
      loop_proc = define_loop_proc(name, klass, loop_config)

      # If the loop is in debug mode, no need to use all kinds of
      # process managers here
      if loop_config['debug_loop']
        worker = Loops::Worker.new(name, @pm, global_config['workers_engine'], 0, &loop_proc)
        loop_proc.call(worker)
      else
        # If wait_period is specified for the loop, update ProcessManager's setting.
        @pm.update_wait_period(loop_config['wait_period']) if loop_config['wait_period']
        @pm.start_workers(name, loop_config['workers_number'] || 1, &loop_proc)
      end
    end

    def create_logger(loop_name, loop_config)
      loop_config['logger'] ||= 'default'

      return Loops.default_logger if loop_config['logger'] == 'default'

      Loops::Logger.new(loop_config['logger'])
    rescue StandardError => e
      message = "Can't create a logger for the #{loop_name} loop! Will log to the default logger!"
      puts "ERROR: #{message}"

      message << "\nException: #{e} at #{e.backtrace.first}"
      error(message)

      Loops.default_logger
    end

    def setup_signals
      stop = proc {
        # We need this because of https://bugs.ruby-lang.org/issues/7917
        Thread.new do
          warn 'Received a signal... stopping...'
        end
        @pm.start_shutdown!
      }

      trap('TERM', stop)
      trap('INT', stop)
      trap('EXIT', stop)
    end

    def fix_ar_after_fork
      return unless Object.const_defined?('ActiveRecord')

      Rails.application.config.allow_concurrency = true if Object.const_defined?('Rails')

      ActiveRecord::Base.clear_all_connections!
      ActiveRecord::Base.connection_pool.connections.map(&:verify!)
    end
  end
end
