# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext/numeric/time'

describe Loops::Base do
  let(:logger) { double('Logger').as_null_object }

  context 'default #run method' do
    it 'should raise an exception requiring descendants to override it' do
      expect { subject.run }.to raise_error(NotImplementedError)
    end
  end

  context '#with_period_of method' do
    it 'should coerce parameters to integer before passing them to sleep' do
      [1, 1.seconds, '1'].each do |period|
        test_iterations = 0
        subject.with_period_of(period) do
          break if test_iterations > 0

          test_iterations += 1
        end
        expect(test_iterations).to eq(1)
      end
    end
  end
end
