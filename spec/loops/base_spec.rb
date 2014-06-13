require 'spec_helper'
require 'active_support/core_ext/numeric/time'

describe Loops::Base do
  let(:logger) { double('Logger').as_null_object }
  let(:loop) { Loops::Base.new(logger, 'simple', {}) }

  context "in #with_period_of method" do
    it "should coerce parameters to integer before passing them to sleep" do
      [ 1, 1.seconds, "1" ].each do |period|
        test_iterations = 0
        loop.with_period_of(period) do
          break if test_iterations > 0
          test_iterations += 1
        end
        test_iterations.should == 1
      end
    end
  end
end
