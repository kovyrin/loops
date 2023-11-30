# frozen_string_literal: true

module Loops
  module Commands
    class MonitorCommand < Loops::Command # :nodoc:
      def execute
        # Send all logs to console, but do not write into a file
        Loops.logger.write_to_console = true
        Loops.logger.default_logfile = File::NULL

        # Set process name
        loops_args = begin
          options[:args].join(' ')
        rescue StandardError
          'all'
        end

        $0 = "loops monitor: #{loops_args}"

        # Start loops and let the monitor process take over
        puts 'Starting loops in monitor mode...'
        engine.start_loops!(options[:args])
        puts 'Monitoring loop is finished, exiting now...'
      end
    end
  end
end
