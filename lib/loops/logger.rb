# frozen_string_literal: true

require 'logger'
require 'delegate'
require 'fileutils'

module Loops
  class Logger < Delegator
    # @return [Boolean]
    #   A value indicating whether all logging output should be
    #   also duplicated to the console.
    attr_reader :write_to_console

    # @return [Boolean]
    #   A value indicating whether critical errors should be highlighted
    #   with ANSI colors in the log.
    attr_reader :colorful_logs

    # Initializes a new instance of the {Logger} class.
    #
    # @param [String, IO] logfile
    #   The log device.  This is a filename (String), <tt>'stdout'</tt> or
    #   <tt>'stderr'</tt> (String), <tt>'default'</tt> for default framework's
    #   log file, or +IO+ object (typically +STDOUT+, +STDERR+,
    #   or an open file).
    # @param [Integer] level
    #   Logging level. Constants are defined in +Logger+ namespace: +DEBUG+, +INFO+,
    #   +WARN+, +ERROR+, +FATAL+, or +UNKNOWN+.
    # @param [Integer] number_of_files
    #   A number of files to keep.
    # @param [Integer] max_file_size
    #   A max file size. When file become larger, next one will be created.
    # @param [Boolean] write_to_console
    #   When +true+, all logging output will be dumped to the +STDOUT+ also.
    #
    def initialize(logfile = $stdout, level = ::Logger::INFO, number_of_files = 10, max_file_size = 100 * 1024 * 1024,
                   write_to_console = false)
      @number_of_files = number_of_files
      @level = level
      @max_file_size = max_file_size
      @write_to_console = write_to_console
      self.logfile = logfile
      super(@implementation)
    end

    # Sets the default log file (see {#logfile=}).
    #
    # @param [String, IO] logfile
    #   the log file path or IO.
    # @return [String, IO]
    #   the log file path or IO.
    #
    def default_logfile=(logfile)
      @default_logfile = logfile
      self.logfile = logfile
    end

    # Sets the log file.
    #
    # @param [String, IO] logfile
    #   The log device.  This is a filename (String), <tt>'stdout'</tt> or
    #   <tt>'stderr'</tt> (String), <tt>'default'</tt> for default framework's
    #   log file, or +IO+ object (typically +STDOUT+, +STDERR+,
    #   or an open file).
    # @return [String, IO]
    #   the log device.
    #
    def logfile=(logfile)
      logfile = @default_logfile || $stdout if logfile == 'default'
      coerced_logfile =
        case logfile
        when 'stdout' then $stdout
        when 'stderr' then $stderr
        when IO, StringIO then logfile
        else
          if Loops.root
            logfile =~ %r{^/} ? logfile : Loops.root.join(logfile).to_s
          else
            logfile
          end
        end
      # Ensure logging directory does exist
      FileUtils.mkdir_p(File.dirname(coerced_logfile)) if coerced_logfile.is_a?(String)

      # Create a logger implementation.
      @implementation = LoggerImplementation.new(coerced_logfile, @number_of_files, @max_file_size, @write_to_console, @colorful_logs)
      @implementation.level = @level
    end

    # Remember the level at the proxy level.
    #
    # @param [Integer] level
    #   Logging severity.
    # @return [Integer]
    #   Logging severity.
    #
    def level=(level)
      @level = level
      @implementation.level = @level if @implementation
    end

    # Sets a value indicating whether to dump all logs to the console.
    #
    # @param [Boolean] value
    #   a value indicating whether to dump all logs to the console.
    # @return [Boolean]
    #   a value indicating whether to dump all logs to the console.
    #
    def write_to_console=(value)
      @write_to_console = value
      @implementation.write_to_console = value if @implementation
    end

    # Sets a value indicating whether to highlight with red ANSI color
    # all critical messages.
    #
    # @param [Boolean] value
    #   a value indicating whether to highlight critical errors in log.
    # @return [Boolean]
    #   a value indicating whether to highlight critical errors in log.
    #
    def colorful_logs=(value)
      @colorful_logs = value
      @implementation.colorful_logs = value if @implementation
    end

    # @private
    # Send everything else to @implementation.
    def __getobj__
      @implementation or raise 'Logger implementation not initialized'
    end

    def __setobj__(obj)
      @implementation = obj
    end

    # @private
    # Delegator's method_missing ignores the &block argument (!!!?)
    def method_missing(m, *, &)
      target = __getobj__
      if target.respond_to?(m)
        target.__send__(m, *, &)
      else
        super(m, *args, &)
      end
    end

    # @private
    class LoggerImplementation < ::Logger
      attr_reader :prefix

      attr_accessor :write_to_console, :colorful_logs

      class Formatter
        def initialize(logger)
          @logger = logger
        end

        def call(severity, time, progname, message)
          log_message = [severity[0..0], time.strftime('%Y-%m-%d %H:%M:%S'), Process.pid]
          log_message << @logger.prefix
          log_message << progname
          log_message << message

          "#{log_message.compact.join(' : ')}\n"
        end
      end

      def initialize(log_device, number_of_files = 10, max_file_size = 10 * 1024 * 1024, write_to_console = true, colorful_logs = false)
        super(log_device, number_of_files, max_file_size)
        self.formatter    = Formatter.new(self)
        @write_to_console = write_to_console
        @colorful_logs    = colorful_logs
        @prefix           = nil
      end

      def add(severity, message = nil, progname = nil, &)
        if @colorful_logs
          message = color_errors(severity, message)
          progname = color_errors(severity, progname)
        end
        super(severity, message, progname, &)
        puts formatter.call(%w[D I W E F A][severity] || 'A', Time.now, progname, message) if @write_to_console && (message || progname)
      rescue StandardError
        # ignore errors in logging
      end

      def with_prefix(prefix)
        raise 'No block given' unless block_given?

        old_prefix = @prefix
        @prefix = prefix
        begin
          yield
        ensure
          @prefix = old_prefix
        end
      end

      def color_errors(severity, line)
        return line if severity < ::Logger::ERROR
        return "\e[31m#{line}\e[0m" if line && line !~ /\e/

        line
      end
    end
  end
end
