# frozen_string_literal: true

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
          opt.banner = "Usage: #{File.basename($PROGRAM_NAME)} command [arg1 [arg2]] [options]"
          opt.separator ''
          opt.separator COMMANDS_HELP
          opt.separator ''
          opt.separator 'Specific options:'

          opt.on('-c', '--config=file', 'Configuration file') do |config_file|
            options[:config_file] = config_file
          end

          opt.on('-d', '--daemonize', 'Daemonize when all loops started') do |_value|
            options[:daemonize] = true
          end

          opt.on('-e', '--environment=env', 'Set LOOPS_ENV/RAILS_ENV/MERB_ENV value') do |env|
            options[:environment] = env
          end

          opt.on('-f', '--framework=name', "Bootstraps Rails (rails - default value) or Merb (merb) before#{SPLIT_HELP_LINE}starting loops. Use \"none\" for plain ruby loops.") do |framework|
            options[:framework] = framework
          end

          opt.on('-l', '--loops=dir', 'Root directory with loops classes') do |loops_root|
            options[:loops_root] = loops_root
          end

          opt.on('-p', '--pid=file', 'Override loops.yml pid_file option') do |pid_file|
            options[:pid_file] = pid_file
          end

          opt.on('-r', '--root=dir', 'Root directory which will be used as a loops home dir (chdir)') do |root|
            options[:root] = root
          end

          opt.on('-Rlibrary', '--require=library', 'require the library before executing the script') do |library|
            options[:require] << library
          end

          opt.on_tail('-h', '--help', 'Show this message') do
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
          daemonize: false,
          config_file: 'config/loops.yml',
          environment: nil, # We'll guess it later
          framework: 'rails',
          loops_root: 'app/loops',
          pid_file: nil,
          root: nil,
          require: []
        }

        begin
          option_parser.parse!(args)
        rescue OptionParser::ParseError => e
          warn e.message
          $stderr << "\n" << option_parser
          exit
        end

        # Root directory
        guess_root_dir
        Loops.root = options.delete(:root)
        Dir.chdir(Loops.root)

        # Config file
        Loops.config_file = options.delete(:config_file)
        # Loops root
        Loops.loops_root  = options.delete(:loops_root)

        @command = extract_command!
        options[:framework] = 'none' unless @command.requires_bootstrap?

        bootstrap!
        start_engine!

        # Pid file
        Loops.pid_file = options.delete(:pid_file)

        @options
      end

      # Extracts command name from arguments.
      #
      # Other parameters are stored in the <tt>:args</tt> option
      # of the {#options} hash.
      #
      # @return [String]
      #   a command name passed.
      #
      def extract_command!
        options[:command], *options[:args] = args
        if options[:command].nil? || options[:command] == 'help'
          puts option_parser
          exit
        end

        unless (command = find_command(options[:command]))
          $stderr << option_parser
          exit
        end
        command
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
        return options[:root] = ENV['LOOPS_ROOT'] if ENV['LOOPS_ROOT']
        # Check root parameter
        return options[:root] if options[:root]

        # Try to detect root dir (should contain app subfolder)
        current_dir = Dir.pwd
        loop do
          if File.directory?(File.join(current_dir, 'app'))
            # Found it!
            return options[:root] = current_dir
          end

          # Move up the FS hierarhy
          pwd = File.expand_path(File.join(current_dir, '..'))
          break if pwd == current_dir # if changing the directory made no difference, then we're at the top

          current_dir = pwd
        end

        # Oops, not app folder found. Use the current dir as the root
        current_dir = Dir.pwd
        options[:root] = current_dir
      end

      #---------------------------------------------------------------------------------------------
      # Detect current environment name or use the default development environment
      #
      # @return [String] environment name
      #
      def guess_environment_name(opt_environment = nil)
        opt_environment || ENV['LOOPS_ENV'] || ENV['RAILS_ENV'] || ENV['MERB_ENV'] || 'development'
      end

      #---------------------------------------------------------------------------------------------
      # Application bootstrap.
      #
      # Checks framework option passed and load application
      # stratup files conrresponding to its value. Also intitalizes
      # the {Loops.default_logger} variable with the framework's
      # default logger value.
      #
      # @return [String]
      #   the used framework name (rails, merb, or none).
      # @raise [InvalidFrameworkError]
      #   occurred when unknown framework option value passed.
      #
      def bootstrap!
        # Guess the environment name
        environment_name = guess_environment_name(options.delete(:environment))

        # Set loop environment name
        Loops.environment = ENV['LOOPS_ENV'] = environment_name

        # Load _require_ dependencies
        options[:require].each do |library|
          require library
        end

        # Bootstrap the requested framework
        framework = options.delete(:framework)
        case framework
        when 'rails'
          # Set rails environment name
          ENV['RAILS_ENV'] = Loops.environment

          # Bootstrap Rails
          require_rails_script('config/boot.rb', 'boot script')
          require_rails_script('config/environment.rb', 'environment script')

          # Loops default logger
          Loops.default_logger = Rails.logger

        when 'merb'
          require 'merb-core'

          # Set merb environment name
          ENV['MERB_ENV'] = Loops.environment

          # Bootstrap Merb
          Merb.start_environment(adapter: 'runner', environment: ENV.fetch('MERB_ENV', nil))

          # Loops default logger
          Loops.default_logger = Merb.logger

        when 'none'
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
      # @return [Engine]
      #   a loops engine instance.
      #
      def start_engine!
        # Start loops engine
        @engine = Loops::Engine.new
        # If pid file option is not passed, get if from loops config ...
        unless options[:pid_file] ||= @engine.global_config['pid_file']
          # ... or try Rails' tmp/pids folder ...
          options[:pid_file] = if Loops.root.join('tmp/pids').directory?
                                 'tmp/pids/loops.pid'
                               else
                                 # ... or use global tmp directory
                                 '/var/tmp/loops.pid'
                               end
        end
        @engine
      end

      COMMANDS_HELP = <<~HELP
        Available commands:
            list                             List available loops (based on config file)
            start                            Start all loops except ones marked with disabled:true in config
            start loop1 [loop2]              Start only loops specified
            stop                             Stop daemonized loops monitor
            monitor                          Start and monitor all enabled loops
                                             (use this with supervisord, runit, upstart or systemd)
            monitor loop1 [loop2]            Start and monitor only loops specified
                                             (use this with supervisord, runit, upstart or systemd)
            stats                            Print loops memory statistics
            debug loop                       Debug specified loop
            help                             Show this message
      HELP

      SPLIT_HELP_LINE = "\n#{' ' * 37}".freeze
    end

    #-----------------------------------------------------------------------------------------------
    # Loads a ruby script from a Rails configuration directory
    def require_rails_script(script, description)
      # Check that we're actually within a rails project directory
      script_path = File.join(Loops.root, script)
      unless File.exist?(script_path)
        puts
        puts "Error: missing Rails #{description}: #{script}"
        puts 'Are you sure current directory is a root of a Rails project?'
        puts "Current dir: #{Loops.root}"
        puts
        exit(1)
      end

      # Load the script
      require(script_path)
    end
  end
end
