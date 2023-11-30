# frozen_string_literal: true

require 'active_support/all'

module Loops
  module Testing # :nodoc:
    extend ActiveSupport::Concern

    # Dumb worker stub
    class Worker
      attr_reader :name, :pm

      def initialize(name, pm)
        @name = name
        @pm = pm
      end
    end

    #-----------------------------------------------------------------------------------------------
    module LoopsExampleGroup
      extend ActiveSupport::Concern

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

      included do
        let(:loop_config) { {}.with_indifferent_access }
        let(:loops_logger) { Logger.new($stdout) }
        let(:loops_process_manager) do
          double('Loops::ProcessManager', logger: loops_logger, shutdown?: false)
        end

        # Define the subject if possible
        if described_class&.ancestors&.include?(Loops::Base)
          subject do
            create_loop(described_class, loop_config)
          end
        end
      end
    end

    #-----------------------------------------------------------------------------------------------
    # Enable loops example group
    RSpec.configure do |config|
      if config.respond_to?(:define_derived_metadata)
        config.include(LoopsExampleGroup, type: :loops)
        config.define_derived_metadata(file_path: %r{/spec/loops/}) do |metadata|
          metadata[:type] = :loops
        end
      else
        config.include(
          LoopsExampleGroup,
          type: :loops,
          example_group: { file_path: %r{/spec/loops/} }
        )
      end
    end
  end
end
