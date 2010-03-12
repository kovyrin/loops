class Loops::Commands::ListCommand < Loops::Command
  def execute
    puts 'Available loops:'
    engine.loops_config.each do |name, config|
      puts "  Loop: #{name}" + (config['disabled'] ? ' (disabled)' : '')
      config.each do |k, v|
        puts "     - #{k}: #{v}"
      end
    end
  end
end