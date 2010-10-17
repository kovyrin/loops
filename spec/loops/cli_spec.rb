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
      @args = [ 'list', '-f', 'none']
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
        cli = Loops::CLI.parse(@args)
        cli.engine.global_config['pid_file'].should == '/var/run/superloops.pid'
      end

      it 'should load config from file specified' do
        cli = Loops::CLI.parse(@args << '-c' << 'config.yml')
        cli.engine.global_config['pid_file'].should == 'tmp/pids/loops.pid'
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
        Loops::CLI.parse(@args)
        Loops.pid_file.should == Pathname.new('/var/run/superloops.pid')
      end

      it 'should absolutize relative pid file path' do
        Loops::CLI.parse(@args << '-c' << 'config.yml')
        Loops.pid_file.should == Pathname.new(RAILS_ROOT).realpath + 'tmp/pids/loops.pid'
      end

      it 'should accept pid file from arguments' do
        Loops::CLI.parse(@args << '-p' << 'superloop.pid')
        Loops.pid_file.should == Pathname.new(RAILS_ROOT).realpath + 'superloop.pid'
      end

      it 'should extract command when passed' do
        cli = Loops::CLI.parse(@args)
        cli.options[:command].should == 'list'
      end

      it 'should extract command arguments when passed' do
        cli = Loops::CLI.parse(@args << 'arg1' << 'arg2')
        cli.options[:command].should == 'list'
        cli.options[:args].should == %w(arg1 arg2)
      end

      it 'should remove all unnecessary options' do
        cli = Loops::CLI.parse(@args << '-r' << RAILS_ROOT << '-p' << 'loop.pid' << '-c' << 'config.yml' << '-l' << '.' << '-d')
        cli.options.keys.map(&:to_s).sort.should == %w(command args daemonize).sort
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

    context 'with Rails framework' do
      before :each do
        @args = [ 'start', 'test', '-r', File.dirname(__FILE__) + '/../rails' ]
        Loops::CLI.parse(@args)
      end

      it 'should load boot file' do
        Object.const_defined?('RAILS_BOOT_LOADED').should be_true
      end

      it 'should load environment file' do
        Object.const_defined?('RAILS_ENVIRONMENT_LOADED').should be_true
      end

      it 'should inialize default logger' do
        Loops.default_logger.should == 'rails default logger'
      end
    end
  end

  describe 'with Loops::CLI::Commands included' do
    before :each do
      @args = [ 'list', '-f', 'none', '-r', RAILS_ROOT]
      @cli = Loops::CLI.parse(@args)
    end

    describe 'in #find_command_possibilities' do
      it 'should return a list of possible commands' do
        @cli.find_command_possibilities('s').sort.should == %w(start stats stop)
        @cli.find_command_possibilities('sta').sort.should == %w(start stats)
        @cli.find_command_possibilities('star').should == %w(start)
        @cli.find_command_possibilities('l').should == %w(list)
        @cli.find_command_possibilities('o').should == []
      end
    end

    describe 'in #find_command' do
      it 'should raise InvalidCommandError when command is not found' do
        expect {
          @cli.find_command('o')
        }.to raise_error(Loops::InvalidCommandError)
      end

      it 'should raise InvalidCommandError when ambiguous command matches found' do
        expect {
          @cli.find_command('s')
        }.to raise_error(Loops::InvalidCommandError)
      end

      it 'should return an instance of command when everything is ok' do
        expect {
          @cli.find_command('star').should be_a(Loops::Commands::StartCommand)
        }.to_not raise_error(Loops::InvalidCommandError)
      end
    end
  end
end
