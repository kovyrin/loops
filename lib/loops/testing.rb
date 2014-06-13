require "active_support/concern"
require "active_support/core_ext/string/inflections"

module Loops
  module Testing
    extend ActiveSupport::Concern

    class Worker
      attr_reader :name, :pm

      def initialize(name, pm)
        @name = name
        @pm = pm
      end
    end

    def self.enable(spec_config)
      spec_config.include(Loops::Testing)
    end

    included do
      let(:loops_logger) { Logger.new(STDOUT) }
      let(:loops_process_manager) { double("Loops::ProcessManager", :logger => loops_logger) }
    end

    # Creates a loop class object with given configuration
    def create_loop(loop_class, config = {})
      loop_name = loop_name_from_class(loop_class)

      worker = Loops::Testing::Worker.new(loop_name, loops_process_manager)
      loop_class.new(worker, loop_name, config)
    end

    # Converts a class name or a class to a loop name
    def loop_name_from_class(loop_class)
      loop_class.to_s.gsub(/Loop$/, '').underscore
    end

  end
end