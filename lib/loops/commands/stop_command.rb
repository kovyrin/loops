# frozen_string_literal: true

module Loops
  module Commands
    class StopCommand < Loops::Command
      def execute
        $stdout.sync = true

        unless Loops::Daemonize.check_pid(Loops.pid_file)
          puts 'WARNING: No pid file or a stale pid file found! Exiting.'
          exit(0)
        end

        pid = Loops::Daemonize.read_pid(Loops.pid_file)
        print "Killing the process: #{pid}: "

        loop do
          Process.kill('SIGTERM', pid)
          sleep(1)
          break unless Loops::Daemonize.check_pid(Loops.pid_file)

          print('.')
        end

        puts ' Done!'
        exit(0)
      end

      def requires_bootstrap?
        false
      end
    end
  end
end
