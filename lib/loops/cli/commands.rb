module Loops
  class CLI
    module Commands
      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods
        def execute
          parse(ARGV).run!
        end
      end

      def run!
        send("cmd_#{options[:command]}")
      end

      def cmd_stop
        STDOUT.sync = true
        raise "No pid file or a stale pid file!" unless Loops::Daemonize.check_pid(options[:pid_file])
        pid = Loops::Daemonize.read_pid(options[:pid_file])
        print "Killing the process: #{pid}: "

        loop do
          Process.kill('SIGTERM', pid)
          sleep(1)
          break unless Loops::Daemonize.check_pid(options[:pid_file])
          print(".")
        end

        puts " Done!"
        exit(0)
      end

      def cmd_list
        puts "Available loops:"
        Loops::Engine.loops_config.each do |name, config|
          puts "Loop: #{name}" + (config['disabled'] ? ' (disabled)' : '')
          config.each do |k,v|
            puts " - #{k}: #{v}"
          end
        end
        puts
        exit(0)
      end

      def cmd_debug
        puts "Starting one loop in debug mode: #{options[:debug_loop]}"
        Loops::Engine.debug_loop!(options[:debug_loop])
        exit(0)
      end

      def cmd_start
        # Pid file check
        if Loops::Daemonize.check_pid(options[:pid_file])
          puts "Can't start, another process exists!"
          exit(1)
        end

        # Daemonization
        if options[:daemonize]
          app_name = "loops monitor: #{options[:loops].join(' ') rescue 'all'}\0"
          Loops::Daemonize.daemonize(app_name)
        end

        # Pid file creation
        puts "Creating PID file"
        Loops::Daemonize.create_pid(options[:pid_file])

        # Workers processing
        puts "Starting workers"
        Loops::Engine.start_loops!(options[:loops])

        # Workers exited, cleaning up
        puts "Cleaning pid file..."
        File.delete(options[:pid_file]) rescue nil
      end
    end
  end
end