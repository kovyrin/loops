%w(commands options).each { |p| require File.join(Loops::LIB_ROOT, 'loops/cli', p) }

module Loops
  class CLI
    include Commands, Options

    register_command :list
    register_command :debug
    register_command :start
    register_command :stop

    # The array of (unparsed) command-line options
    attr_reader :args

    def initialize(args)
      @args = args.dup
    end
  end
end
