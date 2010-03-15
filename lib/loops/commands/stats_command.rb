class Loops::Commands::StatsCommand < Loops::Command
  def execute
    system File.join(Loops::LIB_ROOT, '../bin/loops-memory-stats')
  end
end