require 'yaml'
require 'pp'

class Loops  
  def self.load_config(file)
    @@config = YAML.load_file(file)
    pp @@config
  end
  
  def self.start_loops!
    @@running_loops = []
    @@config.each do |name, config|
      next if config['disabled']
      klass = load_loop_class(name)
      next unless klass

      start_loop(name, klass, config) 
      @@running_loops << name
    end
    
    if @@running_loops.empty?
      puts "WARNING: No loops to run! Exiting..."
      return
    end
    
    EM.run do
      info "Ok. Now we're running the loops #{@@running_loops.inspect}!"
      setup_signals
    end

    info "Loops are stopped now!"
  end

private

  # Proxy logger calls to the default Rails logger
  [ :debug, :error, :fatal, :info, :warn ].each do |meth_name|
    class_eval <<-EVAL
      def self.#{meth_name}(message)
        Rails.logger.#{meth_name} "loops[RUNNER/\#{Process.pid}]: \#{message}"
      end
    EVAL
  end

  def self.load_loop_class(name)
    begin
      klass_file = LOOPS_ROOT + "/app/loops/#{name}.rb" 
      debug "Loading class file: #{klass_file}"
      require(klass_file)
    rescue Exception
      error "Can't load the class file: #{klass_file}. Worker #{name} won't be started!"
      return false
    end
    
    klass_name = name.camelize
    klass = klass_name.constantize rescue nil
    
    unless klass
      error "Can't find class: #{klass_name}. Worker #{name} won't be started!"
      return false
    end

    return klass
  end
  
  def self.start_loop(name, klass, config)
    puts "Starting loop: #{name}"
    info "Starting loop: #{name}"
    info " - config: #{config.inspect}"
    
    EM.fork(config['workers_number'] || 1) do
      debug "Instantiating class: #{klass}"
      looop = klass.new(create_logger(name, config))
      looop.name = name
      looop.config = config
      
      debug "Starting the loop #{name}!"
      begin
        looop.run
      rescue Exception => e
        error "Exception in the loop #{name}: #{e} at #{e.backtrace.first}"
        sleep(5)
      end
    end
  end

  # TODO: Need to add logs rotation parameters
  def self.create_logger(loop_name, config)
    config['logger'] ||= 'default'

    return Rails.logger if config['logger'] == 'default'
    return Logger.new(STDOUT) if config['logger'] == 'stdout'
    return Logger.new(STDERR) if config['logger'] == 'stderr'
    
    config['logger'] = Rails.root + "/" + config['logger'] unless config['logger'] =~ /^\//
    Logger.new(config['logger'])

  rescue Exception => e
    message = "Can't create a logger for the #{loop_name} loop! Will log to the default logger!"
    puts "ERROR: #{message}"

    message << "\nException: #{e} at #{e.backtrace.first}"
    error(message)

    return Rails.logger
  end

  def self.setup_signals
    Signal.trap('INT') { 
      warn "Received an INT signal... stopping..."
      EM.stop 
    }

    Signal.trap('TERM') { 
      warn "Received an INT signal... stopping..."
      EM.stop 
    }    
  end
end

require 'loops/base'
require 'loops/queue'
