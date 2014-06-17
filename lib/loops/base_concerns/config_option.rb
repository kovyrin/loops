require "active_support/concern"
require "loops/exceptions"

module Loops
  module BaseConcerns
    module ConfigOption
      extend ActiveSupport::Concern

      # Backend for configuration options accessor methods
      def read_config_option(name)
        options = self.class.loops_config_options[name] || {}

        # Read config value
        name = name.to_s
        config_value = config[name]

        unless config.has_key?(name)
          if options[:required]
            raise Loops::Exceptions::OptionNotFound, "Could not find option '#{name}'!"
          end
          config_value = options[:default] if options[:default]
        end

        if options[:kind_of]
          config_value = convert_option_value(name, config_value, options[:kind_of])
        end

        return config_value
      end

      #---------------------------------------------------------------------------------------------
      # Converts a given option to a given class
      def convert_option_value(name, value, dest_class)
        # Check if we need to do any conversion at all
        [ *dest_class ].each do |dc|
          return value if value.kind_of?(dc)
        end

        # Ok, we need to convert it, now make sure we have only one destination class
        unless dest_class.is_a?(Class)
          raise ArgumentError, "Ambiguous :kind_of value for option '#{name}': #{dest_class.inspect}"
        end

        # Let's try to do the conversion
        begin
          return value.to_i if dest_class.ancestors.include?(Integer)
          return value.to_f if dest_class.ancestors.include?(Float)
          return value.to_s if dest_class == String
        rescue => e
          error = "Failed to convert option '#{name}' value #{value.inspect} to #{dest_class}: #{e}"
          raise Loops::Exceptions::TypeError, error
        end

        # Ok, no idea how to deal with this shit
        raise ArgumentError, "Unsupported :kind_of value for option '#{name}': #{dest_class}"
      end

      #---------------------------------------------------------------------------------------------
      module ClassMethods
        # Returns configuration option validation params defined by the user
        def loops_config_options
          @config_options || {}
        end

        # Declares a configuration option expected by the loop
        def config_option(name, options = {})
          name = name.to_s

          @config_options ||= {}
          @config_options[name] = options

          class_eval <<-EVAL, __FILE__, __LINE__ + 1
            def #{name}
              read_config_option(#{name.inspect})
            end
          EVAL
        end
      end
    end
  end
end
