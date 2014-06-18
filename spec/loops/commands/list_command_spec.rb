require "spec_helper"

describe Loops::Commands::ListCommand do
  let(:command) { described_class.new }

  context "(private) is_disabled? method" do
    it "should return true if the loop is disabled in config" do
      command.send(:is_disabled?, { :disabled => true }).should be(true)
    end

    it "should return true if the loop config contains enabled = false" do
      command.send(:is_disabled?, { :enabled => false }).should be(true)
    end

    it "should return true if the loop contains disabled = true and enabled = true" do
      command.send(:is_disabled?, { :enabled => true, :disabled => true }).should be(true)
    end

    it "should return false if the loop config does not specify status" do
      command.send(:is_disabled?, {}).should be(false)
    end
  end

  context "when invoked with a bunch of loops" do
    let(:engine) { double("engine") }

    before do
      config = {
        :generic  => { :workers_number => 1 },
        :disabled => { :workers_number => 2, :disabled => true },
        :enabled  => { :workers_number => 3, :enabled => true },
        :fucked   => { :workers_number => 3, :disabled => true, :enabled => true }
      }

      engine.stub(:loops_config).and_return(config)
    end

    it "should successfully print a list of loops" do
      command.invoke(engine, {})
    end
  end
end
