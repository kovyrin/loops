class Loops::Commands::ListCommand < Loops::Command
  def execute
    puts "Available loops (current environment: #{Loops.environment}):"
    engine.loops_config.each do |name, config|
      disabled = is_disabled?(config)
      puts "  Loop: #{name}" + (disabled ? ' (disabled)' : '')
      config.each do |k, v|
        puts "     - #{k}: #{v}"
      end
    end
  end

  def requires_bootstrap?
    false
  end

private

  def is_disabled?(config)
    return true if config[:disabled]
    return true if config.has_key?(:enabled) && !config[:enabled]
    return false
  end

end
