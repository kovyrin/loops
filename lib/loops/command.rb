# frozen_string_literal: true

# Represents a Loops command.
module Loops
  class Command
    # @return [Engine]
    #   The instance of {Engine} to execute command in.
    attr_reader :engine

    # @return [Hash<String, Object>]
    #   The hash of (parsed) command-line options.
    attr_reader :options

    # Initializes a new {Command} instance.
    def initialize; end

    # Invoke a command.
    #
    # Initializes {#engine} and {#options} variables and
    # executes a command.
    #
    def invoke(engine, options)
      @engine = engine
      @options = options

      execute
    end

    # A command entry point. Should be overridden in descendants.
    def execute
      raise NotImplementedError, 'Generic command has no actions'
    end

    # Gets a value indicating whether command needs to bootstrap framework.
    def requires_bootstrap?
      true
    end
  end
end

#---------------------------------------------------------------------------------------------------
# Container module for all commands
module Loops
  module Commands
  end
end

# Load all command classes
commands_dir = File.join(File.dirname(__FILE__), 'commands')
Dir["#{commands_dir}/*_command.rb"].each { |f| require f }
