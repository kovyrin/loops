%w(commands options).each { |p| require File.join(Loops::ROOT, 'loops/cli', p) }

module Loops
  class CLI
    # The array of (unparsed) command-line options
    attr_reader :args

    def initialize(args)
      @args = args.dup
    end

    include Commands, Options
  end
end
