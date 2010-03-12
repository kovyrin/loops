class Loops::Commands::StartCommand < Loops::Command
  def execute
    # Pid file check
    if Loops::Daemonize.check_pid(options[:pid_file])
      puts "Can't start, another process exists!"
      exit(1)
    end

    # Daemonization
    if options[:daemonize]
      app_name = "loops monitor: #{options[:loops].join(' ') rescue 'all'}\0"
      Loops::Daemonize.daemonize(app_name)
    end

    # Pid file creation
    puts "Creating PID file"
    Loops::Daemonize.create_pid(options[:pid_file])

    # Workers processing
    puts "Starting workers"
    engine.start_loops!(options[:args])

    # Workers exited, cleaning up
    puts "Cleaning pid file..."
    File.delete(options[:pid_file]) rescue nil
  end
end