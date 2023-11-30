# frozen_string_literal: true

%w[commands options].each { |p| require File.join(Loops::LIB_ROOT, 'loops/cli', p) }

module Loops
  # Command line interface for the Loops system.
  #
  # Used to parse command line options, initialize engine, and
  # execute command requested.
  #
  # @example
  #   Loops::CLI.execute
  #
  class CLI
    include Options
    include Commands

    # Register all available commands.
    register_command :list
    register_command :debug
    register_command :start
    register_command :stop
    register_command :stats
    register_command :monitor

    # @return [Array<String>]
    #   The +Array+ of (unparsed) command-line options.
    attr_reader :args

    # Initializes a new instance of the {CLI} class.
    #
    # @param [Array<String>] args
    #   an +Array+ of command line arguments.
    #
    def initialize(args)
      @args = args.dup
    end
  end
end
