# frozen_string_literal: true

module Loops
  module Commands
    class MonitorCommand < Loops::Command
      def execute
        # Mirror logging to console
        Loops.logger.write_to_console = true

        # Set process name
        $0 = "loops monitor: #{begin
          options[:args].join(' ')
        rescue StandardError
          'all'
        end}" # + "\0" # TODO: fix this

        # Start loops and let the monitor process take over
        puts 'Starting loops in monitor mode...'
        engine.start_loops!(options[:args])
        puts 'Monitoring loop is finished, exiting now...'
      end
    end
  end
end
