require 'rubygems'
require 'mq'
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
      puts "No loops to run!"
      return
    end
    
    EM.run do
      puts "Ok. Now we're running the loops #{@@running_loops.inspect}!"
      setup_signals
    end
    puts "Loops are stopped now!"
  end

private
  
  def self.load_loop_class(name)
    begin
      klass_file = LOOPS_ROOT + "/loops/#{name}.rb" 
      puts "Loading class file: #{klass_file}"
      require(klass_file)
    rescue Exception
      puts "Can't load the class file: #{klass_file}. Worker #{name} won't be started!"
      return false
    end
    
    klass_name = name.split('_').collect { |word| word.capitalize }.join # name.camelize
    begin
      klass = eval("#{klass_name}")
    rescue NameError
      puts "Can't find class: #{klass_name}. Worker #{name} won't be started!"
      return false
    end

    return klass
  end
  
  def self.start_loop(name, klass, config)
    puts "Starting loop: #{name}"
    puts " - config: #{config.inspect}"
    
    EM.fork(config['workers_number'] || 1) do
      puts "Instantiating class: #{klass}"
      looop = klass.new
      looop.name = name
      looop.config = config
      
      puts "Starting the loop #{name}!"
      looop.run
    end
  end

  def self.setup_signals
    Signal.trap('INT') { 
      puts "Received an INT signal... stopping..."
      EM.stop 
    }

    Signal.trap('TERM') { 
      puts "Received an INT signal... stopping..."
      EM.stop 
    }    
  end
end

require 'loops/base'
require 'loops/queue'
