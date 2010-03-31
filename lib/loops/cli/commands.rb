module Loops
  class CLI
    # Contains methods related to Loops commands: retrieving, instantiating,
    # executing.
    #
    # @example
    #   Loops::CLI.execute(ARGV)
    #
    module Commands
      # @private
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Parse arguments, find and execute command requested.
        #
        def execute
          parse(ARGV).run!
        end

        # Register a Loops command.
        #
        # @param [Symbol, String] command_name
        #   a command name to register.
        #
        def register_command(command_name)
          @@commands ||= {}
          @@commands[command_name.to_sym] = nil
        end

        # Get a list of command names.
        #
        # @return [Array<String>]
        #   an +Array+ of command names.
        #
        def command_names
          @@commands.keys.map { |c| c.to_s }
        end

        # Return the registered command from the command name.
        #
        # @param [Symbol, String] command_name
        #   a command name to register.
        # @return [Command, nil]
        #   an instance of requested command.
        #
        def [](command_name)
          command_name = command_name.to_sym
          @@commands[command_name] ||= load_and_instantiate(command_name)
        end

        # Load and instantiate a given command.
        #
        # @param [Symbol, String] command_name
        #   a command name to register.
        # @return [Command, nil]
        #   an instantiated command or +nil+, when command is not found.
        #
        def load_and_instantiate(command_name)
          command_name = command_name.to_s
          retried = false

          begin
            const_name = command_name.capitalize.gsub(/_(.)/) { $1.upcase }
            Loops::Commands.const_get("#{const_name}Command").new
          rescue NameError
            if retried then
              nil
            else
              retried = true
              require File.join(Loops::LIB_ROOT, 'loops/commands', "#{command_name}_command")
              retry
            end
          end
        end
      end

      # Run command requested.
      #
      # Finds, instantiates and invokes a command.
      #
      def run!
        @command.invoke(engine, options)
      end

      # Find and return an instance of {Command} by command name.
      #
      # @param [Symbol, String] command_name
      #   a command name to register.
      # @return [Command, nil]
      #   an instantiated command or +nil+, when command is not found.
      #
      def find_command(command_name)
        possibilities = find_command_possibilities(command_name)
        if possibilities.size > 1 then
          raise Loops::InvalidCommandError, "Ambiguous command #{command_name} matches [#{possibilities.join(', ')}]"
        elsif possibilities.size < 1 then
          raise Loops::InvalidCommandError, "Unknown command #{command_name}"
        end

        self.class[possibilities.first]
      end

      # Find command possibilities (used to find command by a short name).
      #
      # @param [Symbol, String] command_name
      #   a command name to register.
      # @return [Array<String>]
      #   a list of possible commands matched to the specified short or
      #   full name.
      #
      def find_command_possibilities(command_name)
        len = command_name.length
        self.class.command_names.select { |c| command_name == c[0, len] }
      end
    end
  end
end
