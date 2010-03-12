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

        def register_command(command_name)
          @@commands ||= {}
          @@commands[command_name.to_sym] = nil
        end

        def command_names
          @@commands.keys.map { |c| c.to_s }
        end

        # Return the registered command from the command name.
        def [](command_name)
          command_name = command_name.to_sym
          @@commands[command_name] ||= load_and_instantiate(command_name)
        end

        def load_and_instantiate(command_name)
          command_name = command_name.to_s
          retried = false

          begin
            const_name = command_name.capitalize.gsub(/_(.)/) { $1.upcase }
            puts const_name.inspect
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

      def run!
        if cmd = find_command(options[:command])
          cmd.invoke(engine, options)
        else
          STDERR << option_parser
          exit
        end
      end

      def find_command(command_name)
        possibilities = find_command_possibilities(command_name)
        if possibilities.size > 1 then
          raise "Ambiguous command #{command_name} matches [#{possibilities.join(', ')}]"
        elsif possibilities.size < 1 then
          raise "Unknown command #{command_name}"
        end

        self.class[possibilities.first]
      end

      def find_command_possibilities(command_name)
        len = command_name.length
        self.class.command_names.select { |c| command_name == c[0, len] }
      end
    end
  end
end