class Loops::Commands::StartCommand < Loops::Command
  def execute
    # Pid file check
    if Loops::Daemonize.check_pid(Loops.pid_file)
      puts "Can't start, another process exists!"
      exit(1)
    end

    # Daemonization
    if options[:daemonize]
      app_name = "loops monitor: #{options[:args].join(' ') rescue 'all'}\0"
      Loops::Daemonize.daemonize(app_name)
    end

    # Pid file creation
    begin
      Loops::Daemonize.create_pid(Loops.pid_file)
    rescue => e
      puts
      puts "Error: Failed to create pid file #{Loops.pid_file}!"
      puts "Exception: #{e}"
      puts
      exit(1)
    end

    # Workers processing
    engine.start_loops!(options[:args])

    # Workers exited, cleaning up
    File.delete(Loops.pid_file) rescue nil
  end
end
