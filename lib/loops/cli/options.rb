require 'pathname'
require 'optparse'

module Loops
  class CLI
    module Options
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Return a new CLI instance with the given arguments pre-parsed and
        # ready for execution.
        def parse(args)
          cli = new(args)
          cli.parse_options!
          cli
        end
      end

      # The hash of (parsed) command-line options
      attr_reader :options

      def option_parser
        @option_parser ||= OptionParser.new do |opt|
          opt.banner = "Usage: #{File.basename($0)} [options]"
          opt.separator ""
          opt.separator 'Specific options:'

          opt.on('-d', '--daemonize', 'Daemonize when all loops started') do |daemonize|
            options[:daemonize] = daemonize
          end

          opt.on('-s', '--stop', 'Stop daemonized loops if running.') do |stop|
            options[:stop] = stop
          end

          opt.on('-p', '--pid=file', 'Override loops.yml pid_file option') do |pid_file|
            options[:pid_file] = pid_file
          end

          opt.on('-l', '--loop=loop_name', 'Start specified loop(s) only') do |loop_name|
            options[:loops] << loop_name
          end

          opt.on('-D', '--debug=loop_name', 'Start single instance of a loop in foreground for debugging purposes') do |debug_loop|
            options[:debug_loop] = debug_loop
          end

          opt.on('-a', '--all', 'Start all loops') do |all|
            options[:all_loops] = all
          end

          opt.on('-L', '--list', 'Shows all available loops with their options') do |list|
            options[:list_loops] = list
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

      def parse_options!
        @options = {
          :daemonize => false,
          :loops => [],
          :debug_loop => nil,
          :all_loops => false,
          :list_loops => false,
          :pid_file => nil,
          :stop => false,
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

        Kernel.const_set('LOOPS_ROOT', guess_root_dir)
        Dir.chdir(LOOPS_ROOT)

        extract_command
        bootstrap
        initialize_constants
        load_config
      end

      def extract_command
        options[:command] = if options[:stop]
          :stop
        elsif options[:list_loops]
          :list
        elsif options[:debug_loop]
          :debug
        else
          # Ignore --loop options if --all parameter passed
          options[:loops] = :all if options[:all_loops]

          # Check what loops we gonna run
          if options[:loops].empty?
            STDERR << option_parser
            exit
          end
          :start
        end
      end

      def initialize_constants
        logger = if options[:debug_loop]
          puts "Using console for logging debug information"
          Logger.new($stdout)
        else
          options[:default_logger]
        end
        Kernel.const_set('LOOPS_DEFAULT_LOGGER', logger)
        Kernel.const_set('LOOPS_CONFIG_FILE', File.join(LOOPS_ROOT, 'config/loops.yml'))
      end

      def guess_root_dir
        current_dir = Dir.pwd
        loop do
          if File.directory?(File.join(current_dir, 'app'))
            puts "Using root dir #{current_dir}"
            return current_dir
          end

          pwd = File.expand_path(File.join(current_dir, '..'))
          break if pwd == current_dir # if changing the directory made no difference, then we're at the top
          current_dir = pwd
        end

        current_dir = Dir.pwd
        puts "Root directory guess failed. Using root dir #{current_dir}"
        current_dir
      end

      def bootstrap
        case options[:framework]
          when 'rails' then
            ENV['RAILS_ENV'] = options[:environment] if options[:environment]

            # Bootstrap Rails
            require File.join(LOOPS_ROOT, 'config/boot')
            require File.join(LOOPS_ROOT, 'config/environment')

            # Loops default logger
            options[:default_logger] = Rails.logger
          when 'merb' then
            require 'merb-core'

            ENV['MERB_ENV'] = options[:environment] if options[:environment]

            # Bootstrap Merb
            Merb.start_environment(:adapter => 'runner', :environment => ENV['MERB_ENV'] || 'development')

            # Loops default logger
            options[:default_logger] = Merb.logger
          when 'none' then
            # Plain ruby loops
            options[:default_logger] = Logger.new($stdout)
          else
            abort "Invalid framework name: #{options[:framework]}. Valid values are: none, rails, merb."
        end
      end

      def load_config
        puts "Loading loops config..."
        Loops::Engine.load_config(LOOPS_CONFIG_FILE)
        unless options[:pid_file] ||= Loops::Engine.global_config['pid_file']
          options[:pid_file] = if File.directory?(File.join(LOOPS_ROOT, 'tmp/pids'))
            'tmp/pids/loops.pid'
          else
            '/var/run/loops.pid'
          end
        end

        options[:pid_file] = File.join(LOOPS_ROOT, options[:pid_file]) unless options[:pid_file] =~ /^\//
      end
    end
  end
end
