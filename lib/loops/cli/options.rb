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
      
      attr_reader :engine

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
      end

      def extract_command
        options[:command], *options[:args] = args
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
            require Loops.root + 'config/boot'
            require Loops.root + 'config/environment'

            # Loops default logger
            Loops.default_logger = Rails.logger
          when 'merb' then
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
            abort "Invalid framework name: #{options[:framework]}. Valid values are: none, rails, merb."
        end
      end

      def start_engine
        @engine = Loops::Engine.new
        unless options[:pid_file] ||= @engine.global_config['pid_file']
          options[:pid_file] = if Loops.root.join('tmp/pids').directory?
            'tmp/pids/loops.pid'
          else
            '/var/run/loops.pid'
          end
        end

        options[:pid_file] = Loops.root.join(options[:pid_file]).to_s unless options[:pid_file] =~ /^\//
      end
    end
  end
end
