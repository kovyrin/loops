class Loops::Engine
  attr_reader :config

  attr_reader :loops_config

  attr_reader :global_config

  def initialize
    load_config
  end

  def load_config
    # load and parse with erb
    raw_config = File.read(Loops.config_file)
    erb_config = ERB.new(raw_config).result

    @config = YAML.load(erb_config)
    @loops_config  = @config['loops']
    @global_config = {
      'poll_period'    => 1,
      'workers_engine' => 'fork'
    }.merge(@config['global'])

    Loops.logger.default_logfile = @global_config['logger'] || $stdout
    Loops.logger.colorful_logs = @global_config['colorful_logs'] || @global_config['colourful_logs']
  end

  def start_loops!(loops_to_start = [])
    @running_loops = []
    @pm = Loops::ProcessManager.new(global_config, Loops.logger)

    # Start all loops
    loops_config.each do |name, config|
      next if config['disabled']
      next unless loops_to_start.empty? || loops_to_start.member?(name)

      klass = load_loop_class(name, config)
      next unless klass

      start_loop(name, klass, config)
      @running_loops << name
    end

    # Do not continue if there is nothing to run
    if @running_loops.empty?
      puts 'WARNING: No loops to run! Exiting...'
      return
    end

    # Start monitoring loop
    setup_signals
    @pm.monitor_workers

    info 'Loops are stopped now!'
  end

  def debug_loop!(loop_name)
    @pm = Loops::ProcessManager.new(global_config, Loops.logger)
    loop_config = loops_config[loop_name] || {}

    # Adjust loop config values before starting it in debug mode
    loop_config['workers_number'] = 1
    loop_config['debug_loop'] = true

    # Load loop class
    unless klass = load_loop_class(loop_name, loop_config)
      puts "Can't load loop class!"
      return false
    end

    # Start the loop
    start_loop(loop_name, klass, loop_config)
  end

  private

    # Proxy logger calls to the default loops logger
    [ :debug, :error, :fatal, :info, :warn ].each do |meth_name|
      class_eval <<-EVAL, __FILE__, __LINE__
        def #{meth_name}(message)
          Loops.logger.#{meth_name} "loops[RUNNER/\#{Process.pid}]: \#{message}"
        end
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

      klass_name = "#{loop_name}_loop".split('/').map { |x| x.capitalize.gsub(/_(.)/) { $1.upcase } }.join('::')
      klass = Object.const_get(klass_name) rescue nil
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

      return klass
    end

    def start_loop(name, klass, config)
      info "Starting loop: #{name}"
      info " - config: #{config.inspect}"

      begin
        if klass.respond_to?(:initialize_loop)
          debug "Initializing loop"
          klass.initialize_loop(config)
          debug "Initialization successful"
        end
      rescue Exception => e
        error("Initialization failed: #{e.message}\n  " + e.backtrace.join("\n  "))
        return
      end

      loop_proc = Proc.new do
        the_logger = begin
            if Loops.logger.is_a?(Loops::Logger) && @global_config['workers_engine'] == 'fork'
              # this is happening right after the fork, therefore no need for teardown at the end of the proc
              Loops.logger.logfile = config['logger']
              Loops.logger
            else
              # for backwards compatibility and handling threading engine
              create_logger(name, config)
            end
        end

        # Set logger level
        if String === config['log_level']
          level = Logger::Severity.const_get(config['log_level'].upcase) rescue nil
          the_logger.level = level if level
        elsif Integer === config['log_level']
          the_logger.level = config['log_level']
        end

        # Colorize logging?
        if the_logger.respond_to?(:colorful_logs=) && (config.has_key?('colorful_logs') || config.has_key?('colourful_logs'))
          the_logger.colorful_logs = config['colorful_logs'] || config['colourful_logs']
        end

        debug "Instantiating class: #{klass}"
        the_loop = klass.new(@pm, name, config)

        debug "Starting the loop #{name}!"
        fix_ar_after_fork
        # reseed the random number generator in case Loops calls
        # srand or rand prior to forking
        srand
        the_loop.run
      end

      # If the loop is in debug mode, no need to use all kinds of
      # process managers here
      if config['debug_loop']
        loop_proc.call
      else
        @pm.start_workers(name, config['workers_number'] || 1) { loop_proc.call }
      end
    end

    def create_logger(loop_name, config)
      config['logger'] ||= 'default'

      return Loops.default_logger if config['logger'] == 'default'
      Loops::Logger.new(config['logger'])

    rescue Exception => e
      message = "Can't create a logger for the #{loop_name} loop! Will log to the default logger!"
      puts "ERROR: #{message}"

      message << "\nException: #{e} at #{e.backtrace.first}"
      error(message)

      return Loops.default_logger
    end

    def setup_signals
      stop = proc {
        warn "Received a signal... stopping..."
        @pm.start_shutdown!
      }

      trap('TERM', stop)
      trap('INT', stop)
      trap('EXIT', stop)
    end

    def fix_ar_after_fork
      if Object.const_defined?('ActiveRecord')
        if Rails::VERSION::MAJOR < 3
          ActiveRecord::Base.allow_concurrency = true
        else
          Rails.application.config.allow_concurrency = true
        end
        ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.verify_active_connections!
      end
    end
end
