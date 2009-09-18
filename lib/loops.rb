require 'yaml'
require 'loops/logger'

class Loops
  cattr_reader :config
  cattr_reader :loops_config
  cattr_reader :global_config

  @@config = {}

  def self.load_config(file)
    @@config = YAML.load_file(file)
    @@global_config = @@config['global']
    @@loops_config = @@config['loops']
    
    Loops.logger.default_logfile = @@config['global']['logger'] || $stdout
  end
  
  def self.start_loops!(loops_to_start = :all)
    @@running_loops = []
    @@pm = Loops::ProcessManager.new(global_config, Loops.logger)
    
    # Start all loops
    loops_config.each do |name, config|
      next if config['disabled']
      next unless loops_to_start == :all || loops_to_start.member?(name)
      klass = load_loop_class(name)
      next unless klass

      start_loop(name, klass, config)
      @@running_loops << name
    end
    
    # Do not continue if there is nothing to run
    if @@running_loops.empty?
      puts "WARNING: No loops to run! Exiting..."
      return
    end

    # Start monitoring loop
    setup_signals
    @@pm.monitor_workers

    info "Loops are stopped now!"
  end

  def self.debug_loop!(loop_name)
    @@pm = Loops::ProcessManager.new(global_config, Loops.logger)
    loop_config = loops_config[loop_name]
    
    # Adjust loop config values before starting it in debug mode
    loop_config['workers_number'] = 1
    loop_config['debug_loop'] = true
    
    # Load loop class
    unless klass = load_loop_class(loop_name)
      puts "Can't load loop class!"
      return false
    end
    
    # Start the loop
    start_loop(name, klass, loop_config)
  end

private

  # Proxy logger calls to the default loops logger
  [ :debug, :error, :fatal, :info, :warn ].each do |meth_name|
    class_eval <<-EVAL, __FILE__, __LINE__
      def self.#{meth_name}(message)
        LOOPS_DEFAULT_LOGGER.#{meth_name} "loops[RUNNER/\#{Process.pid}]: \#{message}"
      end
    EVAL
  end

  def self.load_loop_class(name)
    klass_files = [LOOPS_ROOT + "/app/loops/#{name}_loop.rb", "#{name}_loop"]
    begin
      klass_file = klass_files.shift
      debug "Loading class file: #{klass_file}"
      require(klass_file)
    rescue LoadError
      retry unless klass_files.empty?
      error "Can't load the class file: #{klass_file}. Worker #{name} won't be started!"
      return false
    end
    
    klass_name = "#{name}_loop".classify
    klass = klass_name.constantize rescue nil
    
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
  
  def self.start_loop(name, klass, config)
    puts "Starting loop: #{name}"
    info "Starting loop: #{name}"
    info " - config: #{config.inspect}"

    loop_proc = Proc.new do
      the_logger =
          if Loops.logger.is_a?(Loops::Logger) && @@global_config['workers_engine'] == 'fork'
            # this is happening right after the fork, therefore no need for teardown at the end of the proc
            Loops.logger.logfile = config['logger']
            Loops.logger
          else
            # for backwards compatibility and handling threading engine
            create_logger(name, config)
          end 

      debug "Instantiating class: #{klass}"
      the_loop = klass.new(the_logger)
      the_loop.name = name
      the_loop.config = config

      debug "Starting the loop #{name}!"
      fix_ar_after_fork
      the_loop.run
    end
    
    # If the loop is in debug mode, no need to use all kinds of process managers here
    if config['debug_loop']
      loop_proc.call
    else
      @@pm.start_workers(name, config['workers_number'] || 1) { loop_proc.call }
    end
  end

  def self.create_logger(loop_name, config)
    config['logger'] ||= 'default'

    return LOOPS_DEFAULT_LOGGER if config['logger'] == 'default'
    return Logger.new($stdout) if config['logger'] == 'stdout'
    return Logger.new($stderr) if config['logger'] == 'stderr'
    
    config['logger'] = File.join(LOOPS_ROOT, config['logger']) unless config['logger'] =~ /^\//
    Logger.new(config['logger'])

  rescue Exception => e
    message = "Can't create a logger for the #{loop_name} loop! Will log to the default logger!"
    puts "ERROR: #{message}"

    message << "\nException: #{e} at #{e.backtrace.first}"
    error(message)

    return LOOPS_DEFAULT_LOGGER
  end

  def self.setup_signals
    trap('TERM') {
      warn "Received a TERM signal... stopping..."
      @@pm.stop_workers!
    }

    trap('INT') { 
      warn "Received an INT signal... stopping..."
      @@pm.stop_workers!
    }

    trap('EXIT') { 
      warn "Received a EXIT 'signal'... stopping..."
      @@pm.stop_workers!
    }
  end
  
  def self.fix_ar_after_fork
    ActiveRecord::Base.allow_concurrency = true
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.verify_active_connections!
  end

  def self.logger
    @logger ||= ::Loops::Logger.new
  end

  def self.logger=(the_logger)
    @logger = the_logger
  end

end

require 'loops/process_manager'
require 'loops/base'
require 'loops/queue'
