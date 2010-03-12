require 'spec/spec_helper'

describe Loops do
  describe '.load_config' do
    before :each do
      @config_file = File.join(RAILS_ROOT, 'config/loops.yml')
    end
    
    it 'should load and parse Loops configuration file' do
      Loops::Engine.load_config(@config_file)
      Loops::Engine.config.should be_an_instance_of(Hash)
      Loops::Engine.global_config.should be_an_instance_of(Hash)
      Loops::Engine.loops_config.should be_an_instance_of(Hash)
    end

    it 'should process ERB in config file' do
      Loops::Engine.load_config(@config_file)
      Loops::Engine.global_config['loops_root'].should == LOOPS_ROOT
    end
  end
end