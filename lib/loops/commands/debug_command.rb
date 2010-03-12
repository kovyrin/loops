class Loops::Commands::DebugCommand < Loops::Command
  def execute
    puts "Starting one loop in debug mode: #{options[:args].first}"
    engine.debug_loop!(options[:args].first)
    exit(0)
  end
end