# frozen_string_literal: true

module Loops
  module Commands
    class StatsCommand < Loops::Command
      def execute
        system File.join(Loops::LIB_ROOT, '../bin/loops-memory-stats')
      end

      def requires_bootstrap?
        false
      end
    end
  end
end
