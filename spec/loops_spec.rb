require 'spec_helper'

describe Loops do
  describe '.load_config' do
    before :each do
      Loops.root = RAILS_ROOT
      @engine = Loops::Engine.new
    end

    it 'should load and parse Loops configuration file' do
      @engine.config.should be_an_instance_of(Hash)
      @engine.global_config.should be_an_instance_of(Hash)
      @engine.loops_config.should be_an_instance_of(Hash)
    end

    it 'should process ERB in config file' do
      @engine.global_config['loops_root'].should == Pathname.new(RAILS_ROOT).realpath.to_s
    end
  end
end
