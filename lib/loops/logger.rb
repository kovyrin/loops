require 'logger'
require 'delegate'

class Loops
  class Logger < ::Delegator

    def initialize(logfile = $stdout, level = ::Logger::INFO, number_of_files = 10, max_file_size = 100 * 1024 * 1024,
                   write_to_console = false)
      @number_of_files, @level, @max_file_size, @write_to_console =
          number_of_files, level, max_file_size, write_to_console
      self.logfile = logfile
      super(@implementation)
    end

    def default_logfile=(logfile)
      @default_logfile = logfile
      self.logfile = logfile
    end

    def logfile=(logfile)
      logfile = @default_logfile || $stdout if logfile == 'default'
      coerced_logfile =
          case logfile
          when 'stdout' then $stdout
          when 'stderr' then $stderr
          when IO, StringIO then logfile  
          else
            if defined? LOOPS_ROOT
              logfile =~ /^\// ? logfile : File.join(LOOPS_ROOT, logfile)
            else
              logfile
            end 
          end
      @implementation = LoggerImplementation.new(coerced_logfile, @number_of_files, @max_file_size, @write_to_console)
      @implementation.level = @level
      logfile
    end

    # remember the level at the proxy level
    def level=(level)
      @level = level
      @implementation.level = @level if @implementation
      level
    end

    # send everything else to @implementation
    def __getobj__
      @implementation or raise "Logger implementation not initialized"
    end

    # Delegator's method_missing ignores the &block argument (!!!?)
    def method_missing(m, *args, &block)
      target = self.__getobj__
      unless target.respond_to?(m)
        super(m, *args, &block)
      else
        target.__send__(m, *args, &block)
      end
    end

    class LoggerImplementation < ::Logger

      attr_reader :prefix

      class Formatter

        def initialize(logger)
          @logger = logger
        end

        def call(severity, time, progname, message)
          if @logger.prefix.blank?
            "#{severity[0..0]} : #{time.strftime('%Y-%d-%m %H:%M:%S')} : #{message || progname}\n"
          else
            "#{severity[0..0]} : #{time.strftime('%Y-%d-%m %H:%M:%S')} : #{@logger.prefix} : #{message || progname}\n"
          end
        end
      end

      def initialize(log_device, number_of_files = 10, max_file_size = 10 * 1024 * 1024, write_to_console = true)
        super(log_device, number_of_files, max_file_size)
        self.formatter = Formatter.new(self)
        @write_to_console = write_to_console
        @prefix = nil
      end

      def add(severity, message = nil, progname = nil, &block)
        begin
          super
          if @write_to_console && (message || progname)
            puts self.formatter.call(%w(D I W E F A)[severity] || 'A', Time.now, progname, message)
          end
        rescue
          # ignore errors in logging
        end
      end

      def with_prefix(prefix)
        raise "No block given" unless block_given?
        old_prefix = @prefix
        @prefix = prefix
        begin
          yield
        ensure
          @prefix = old_prefix
        end
      end

    end
  end

end