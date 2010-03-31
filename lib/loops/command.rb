# Represents a Loops command.
class Loops::Command
  # @return [Engine]
  #   The instance of {Engine} to execute command in.
  attr_reader :engine

  # @return [Hash<String, Object>]
  #   The hash of (parsed) command-line options.
  attr_reader :options

  # Initializes a new {Command} instance.
  def initialize
  end

  # Invoke a command.
  #
  # Initiaizes {#engine} and {#options} variables and
  # executes a command.
  #
  def invoke(engine, options)
    @engine = engine
    @options = options

    execute
  end

  # A command entry point. Should be overridden in descendants.
  #
  def execute
    raise 'Generic command has no actions'
  end

  # Gets a value indicating whether command needs to bootstrap framework.
  def requires_bootstrap?
    true
  end
end

# All Loops command registered.
module Loops::Commands
end
