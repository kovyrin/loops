# frozen_string_literal: true

require 'spec_helper'

describe Loops do
  describe '.load_config' do
    before :each do
      Loops.root = RAILS_ROOT
      @engine = Loops::Engine.new
    end

    it 'should load and parse Loops configuration file' do
      expect(@engine.config).to be_an_instance_of(Hash)
      expect(@engine.global_config).to be_an_instance_of(Hash)
      expect(@engine.loops_config).to be_an_instance_of(Hash)
    end

    it 'should process ERB in config file' do
      expect(@engine.global_config['loops_root']).to eq(Pathname.new(RAILS_ROOT).realpath.to_s)
    end
  end
end
