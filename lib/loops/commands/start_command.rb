# frozen_string_literal: true

module Loops
  module Commands
    class StartCommand < Loops::Command
      def execute
        # Pid file check
        if Loops::Daemonize.check_pid(Loops.pid_file)
          puts "Can't start, another process exists!"
          exit(1)
        end

        # Daemonization
        if options[:daemonize]
          app_name = "loops monitor: #{begin
            options[:args].join(' ')
          rescue StandardError
            'all'
          end}"
          Loops::Daemonize.daemonize(app_name)
        end

        # Pid file creation
        begin
          Loops::Daemonize.create_pid(Loops.pid_file)
        rescue StandardError => e
          puts
          puts "Error: Failed to create pid file #{Loops.pid_file}!"
          puts "Exception: #{e}"
          puts
          exit(1)
        end

        # Workers processing
        engine.start_loops!(options[:args])

        # Workers exited, cleaning up
        begin
          File.delete(Loops.pid_file)
        rescue StandardError
          nil
        end
      end
    end
  end
end
