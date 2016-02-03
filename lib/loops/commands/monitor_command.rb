class Loops::Commands::MonitorCommand < Loops::Command
  def execute
    # Mirror logging to console
    Loops.logger.write_to_console = true

    # Set process name
    $0 = "loops monitor: #{options[:args].join(' ') rescue 'all'}"

    # Start loops and let the monitor process take over
    puts "Starting loops in monitor mode..."
    engine.start_loops!(options[:args])
    puts "Monitoring loop is finished, exiting now..."
  end
end
