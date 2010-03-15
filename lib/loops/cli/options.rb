require 'pathname'
require 'optparse'

module Loops
  class CLI
    # Contains methods to parse startup options, bootstrap application,
    # and prepare #{CLI} class to run.
    #
    # @example
    #   Loops::CLI.parse(ARGV)
    #
    module Options
      # @private
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Return a new {CLI} instance with the given arguments pre-parsed and
        # ready for execution.
        #
        # @param [Array<String>] args
        #   an +Array+ of options.
        # @return [CLI]
        #   an instance of {CLI} with the given arguments pre-parsed.
        #
        def parse(args)
          cli = new(args)
          cli.parse_options!
          cli
        end
      end

      # @return [Hash<Symbol, Object>]
      #   The hash of (parsed) command-line options.
      attr_reader :options

      # @return [Engine]
      #   The loops engine instance.
      attr_reader :engine

      # Returns an option parser configured with all options
      # available.
      #
      # @return [OptionParser]
      #   an option parser instance.
      #
      def option_parser
        @option_parser ||= OptionParser.new do |opt|
          opt.banner = "Usage: #{File.basename($0)} [options]"
          opt.separator ''
          opt.separator 'Available commands:'
          opt.separator ''
          opt.separator 'Specific options:'

          opt.on('-d', '--daemonize', 'Daemonize when all loops started') do |daemonize|
            options[:daemonize] = true
          end

          opt.on('-p', '--pid=file', 'Override loops.yml pid_file option') do |pid_file|
            options[:pid_file] = pid_file
          end

          opt.on('-f', '--framework=name', 'Bootstraps Rails (rails - default value) or Merb (merb) before starting loops. Use "none" for plain ruby loops.') do |framework|
            options[:framework] = framework
          end

          opt.on('-e', '--environment=env', 'Set RAILS_ENV (MERB_ENV) value') do |env|
            options[:environment] = env
          end

          opt.on('-rlibrary', '--require=library', 'require the library before executing the script') do |library|
            require library
          end

          opt.on_tail("-h", "--help", "Show this message") do
            puts(opt)
            exit(0)
          end
        end
      end

      # Parses startup options, bootstraps application, starts loops engine.
      #
      # Method exits process when unknown option passed or
      # invalid value specified.
      #
      # @return [Hash]
      #   a hash of parsed options.
      #
      def parse_options!
        @options = {
          :daemonize => false,
          :pid_file => nil,
          :framework => 'rails',
          :environment => nil
        }

        begin
          option_parser.parse!(args)
        rescue OptionParser::ParseError => e
          STDERR.puts e.message
          STDERR << "\n" << option_parser
          exit
        end

        Loops.root = guess_root_dir
        Dir.chdir(Loops.root)

        extract_command
        bootstrap
        start_engine

        @options
      end

      # Extracts command name from arguments.
      #
      # Other parameters are stored in the <tt>:args</tt> option
      # of the {#options} hash.
      #
      # @return [String]
      #   a command name passed.
      def extract_command!
        options[:command], *options[:args] = args
        options[:command]
      end

      # Detect the application root directory (contatining "app"
      # subfolder).
      #
      # @return [String]
      #   absolute path of the application root directory.
      #
      def guess_root_dir
        # Check for environment variable LOOP_ROOT containing
        # the application root folder
        if ENV['LOOPS_ROOT']
          puts "Using root directory #{ENV['LOOPS_ROOT']} from LOOPS_ROOT environment variable"
          return ENV['LOOPS_ROOT']
        end

        # Try to detect root dir (should contain app subfolder)
        current_dir = Dir.pwd
        loop do
          if File.directory?(File.join(current_dir, 'app'))
            # Found it!
            puts "Using root directory #{current_dir}"
            return current_dir
          end

          # Move up the FS hierarhy
          pwd = File.expand_path(File.join(current_dir, '..'))
          break if pwd == current_dir # if changing the directory made no difference, then we're at the top
          current_dir = pwd
        end

        # Oops, not app folder found. Use the current dir as the root
        current_dir = Dir.pwd
        puts "Root directory guess failed. Using root dir #{current_dir}"
        current_dir
      end

      # Application bootstrap.
      #
      # Checks framework option passed and load application
      # stratup files conrresponding to its value. Also intitalizes
      # the {Loops.default_logger} variable with the framework's
      # default logger value.
      #
      # @raise [InvalidFrameworkError]
      #   occurred when unknown framework option value passed.
      #
      def bootstrap
        case options[:framework]
          when 'rails'
            ENV['RAILS_ENV'] = options[:environment] if options[:environment]

            # Bootstrap Rails
            require Loops.root + 'config/boot'
            require Loops.root + 'config/environment'

            # Loops default logger
            Loops.default_logger = Rails.logger
          when 'merb'
            require 'merb-core'

            ENV['MERB_ENV'] = options[:environment] if options[:environment]

            # Bootstrap Merb
            Merb.start_environment(:adapter => 'runner', :environment => ENV['MERB_ENV'] || 'development')

            # Loops default logger
            Loops.default_logger = Merb.logger
          when 'none' then
            # Plain ruby loops
            Loops.default_logger = Loops::Logger.new($stdout)
          else
            raise InvalidFrameworkError, "Invalid framework name: #{options[:framework]}. Valid values are: none, rails, merb."
        end
      end

      # Initializes a loops engine instance.
      #
      # Method loads and parses loops config file, and then
      # initializes pid file path.
      #
      def start_engine
        # Start loops engine
        @engine = Loops::Engine.new
        # If pid file option is not passed, get if from loops config ...
        unless options[:pid_file] ||= @engine.global_config['pid_file']
          # ... or try Rails' tmp/pids folder ...
          options[:pid_file] = if Loops.root.join('tmp/pids').directory?
            'tmp/pids/loops.pid'
          else
            # ... or use global system pids folder
            '/var/run/loops.pid'
          end
        end

        # Resolve relative pid file path
        options[:pid_file] = Loops.root.join(options[:pid_file]).to_s unless options[:pid_file] =~ /^\//
      end
    end
  end
end
