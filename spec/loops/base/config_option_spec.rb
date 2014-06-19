require 'spec_helper'

describe Loops::Base, ".config_option method" do
  class OptionTestLoop < Loops::Base
  end

  it "should define an accessor method with the given name" do
    OptionTestLoop.config_option(:foo)
    expect(create_loop(OptionTestLoop)).to respond_to(:foo)
  end

  context "auto-generated accessor method" do
    it "should return config option value" do
      OptionTestLoop.config_option(:hello)
      expect(create_loop(OptionTestLoop, "hello" => "world").hello).to eq("world")
    end

    context "when option is not present in the config" do
      it "should raise an exception if the option is required to be present" do
        OptionTestLoop.config_option(:hello, :required => true)
        expect { create_loop(OptionTestLoop).hello }.to raise_error(Loops::Exceptions::OptionNotFound)
      end

      it "should return default value if default value has been provided" do
        OptionTestLoop.config_option(:hello, :default => 123)
        expect(create_loop(OptionTestLoop).hello).to eq(123)
      end

      it "should return nil if no default is provided" do
        OptionTestLoop.config_option(:hello)
        expect(create_loop(OptionTestLoop).hello).to be(nil)
      end
    end

    context "when :kind_of parameter is provided" do
      it "should return value as is if conversion is not required" do
        OptionTestLoop.config_option(:hello, :kind_of => Array)
        expect(create_loop(OptionTestLoop, "hello" => [ 42 ]).hello).to eq([ 42 ])
      end

      it "should coerce value to a given class (Integer)" do
        OptionTestLoop.config_option(:hello, :kind_of => Integer)
        expect(create_loop(OptionTestLoop, "hello" => 123).hello).to eq(123)
        expect(create_loop(OptionTestLoop, "hello" => "123").hello).to eq(123)
        expect(create_loop(OptionTestLoop, "hello" => nil).hello).to eq(0)
      end

      it "should coerce value to a given class (Float)" do
        OptionTestLoop.config_option(:hello, :kind_of => Float)
        expect(create_loop(OptionTestLoop, "hello" => 3.14).hello).to eq(3.14)
        expect(create_loop(OptionTestLoop, "hello" => "3.14").hello).to eq(3.14)
      end

      it "should coerce value to a given class (String)" do
        OptionTestLoop.config_option(:hello, :kind_of => String)
        expect(create_loop(OptionTestLoop, "hello" => 42).hello).to eq("42")
        expect(create_loop(OptionTestLoop, "hello" => "42").hello).to eq("42")
        expect(create_loop(OptionTestLoop, "hello" => nil).hello).to eq("")
        expect(create_loop(OptionTestLoop, "hello" => true).hello).to eq("true")
        expect(create_loop(OptionTestLoop, "hello" => false).hello).to eq("false")
      end

      it "should raise an exception when could not convert a value" do
        OptionTestLoop.config_option(:hello, :kind_of => Integer)
        expect { create_loop(OptionTestLoop, "hello" => false).hello }.to raise_error(Loops::Exceptions::TypeError)
      end

      it "should raise an exception when kind_of-based conversion is not supported" do
        OptionTestLoop.config_option(:hello, :kind_of => Array)
        expect { create_loop(OptionTestLoop, "hello" => 1).hello }.to raise_error(ArgumentError)
      end
    end
  end
end
