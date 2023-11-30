# frozen_string_literal: true

module Loops
  module Commands
    class DebugCommand < Loops::Command
      def execute
        Loops.logger.write_to_console = true
        puts "Starting one loop in debug mode: #{options[:args].first}"
        engine.debug_loop!(options[:args].first)
        exit(0)
      end
    end
  end
end
