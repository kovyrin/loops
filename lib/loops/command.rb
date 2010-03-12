class Loops::Command
  attr_reader :engine
  
  attr_reader :options
  
  def initialize
  end

  def invoke(engine, options)
    @engine = engine
    @options = options
    
    execute
  end
  
  def execute
    raise 'Generic command has no actions'
  end
end

module Loops::Commands
end
