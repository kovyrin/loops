require 'spec/spec_helper'

describe Loops::CLI do
  it 'should include Loops::CLI::Options' do
    Loops::CLI.included_modules.should include(Loops::CLI::Options)
  end

  it 'should include Loops::CLI::Commands' do
    Loops::CLI.included_modules.should include(Loops::CLI::Commands)
  end

  describe 'with Loops::CLI::Options included' do
    before :each do
      @args = [ '-f', 'none']
    end

    context 'when current directory could be detected' do
      before :each do
        Dir.chdir(RAILS_ROOT)
      end

      it 'should detect root directory' do
        Loops::CLI.parse(@args)
        Loops.root.should == Pathname.new(RAILS_ROOT).realpath
      end

      it 'should chdir to the root directory' do
        Loops::CLI.parse(@args)
        Dir.pwd.should == Pathname.new(RAILS_ROOT).realpath.to_s
      end

      it 'should load config from config/loops.yml by default' do
        @cli = Loops::CLI.parse(@args)
        @cli.engine.global_config['pid_file'].should == '/var/run/superloops.pid'
      end

      it 'should load config from file specified' do
        @cli = Loops::CLI.parse(@args << '-c' << 'config.yml')
        @cli.engine.global_config['pid_file'].should == 'tmp/pids/loops.pid'
      end

      it 'should initialize use app/loops as a root directory for loops by default' do
        Loops::CLI.parse(@args)
        Loops.loops_root.should == Pathname.new(RAILS_ROOT + '/app/loops').realpath
      end

      it 'should use specified root directory for loops' do
        Loops::CLI.parse(@args << '-l' << '.')
        Loops.loops_root.should == Pathname.new(RAILS_ROOT).realpath
      end

      it 'should use pid file from global config section' do
        @cli = Loops::CLI.parse(@args)
        Loops.pid_file.should == Pathname.new('/var/run/superloops.pid')
      end

      it 'should absolutize relative pid file path' do
        @cli = Loops::CLI.parse(@args << '-c' << 'config.yml')
        Loops.pid_file.should == Pathname.new(RAILS_ROOT).realpath + 'tmp/pids/loops.pid'
      end

      it 'should accept pid file from arguments' do
        @cli = Loops::CLI.parse(@args << '-p' << 'superloop.pid')
        Loops.pid_file.should == Pathname.new(RAILS_ROOT).realpath + 'superloop.pid'
      end
    end

    context 'when root directory passed in arguments' do
      before :each do
        @args << '-r' << File.dirname(__FILE__) + '/../rails'
      end

      it 'should detect root directory' do
        Loops::CLI.parse(@args)
        Loops.root.should == Pathname.new(RAILS_ROOT).realpath
      end

      it 'should chdir to the root directory' do
        Loops::CLI.parse(@args)
        Dir.pwd.should == Pathname.new(RAILS_ROOT).realpath.to_s
      end
    end
  end
end
