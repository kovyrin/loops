require 'yaml'

class Loops  
  def self.load_config(file)
    @@config = YAML.load_file(file)
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
      klass_file = LOOPS_ROOT + "/loops/#{name}.rb" 
      debug "Loading class file: #{klass_file}"
      require(klass_file)
    rescue Exception
      error "Can't load the class file: #{klass_file}. Worker #{name} won't be started!"
      return false
    end
    
    klass_name = name.camelize
    klass = klass_name.constantize
    
    unless klass
      error "Can't find class: #{klass_name}. Worker #{name} won't be started!"
      return false
    end

    return klass
  end
  
  def self.start_loop(name, klass, config)
    info "Starting loop: #{name}"
    info " - config: #{config.inspect}"
    
    EM.fork(config['workers_number'] || 1) do
      debug "Instantiating class: #{klass}"
      looop = klass.new(Rails.logger)
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
