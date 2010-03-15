require 'yaml'
require 'erb'
require 'pathname'

module Loops
  # @return [String]
  #   a full path to the loops "lib" directory.
  LIB_ROOT = File.expand_path(File.dirname(__FILE__))
  # @return [String]
  #   a full path to the loops binary file.
  BINARY   = File.expand_path(File.join(LIB_ROOT, '../bin/loops'))

  def self.root
    @@root
  end

  def self.root=(path)
    @@root = Pathname.new(path)
  end

  def self.config_file
    @@config_file ||= root.join('config/loops.yml')
  end

  def self.config_file=(config_file)
    @@config_file = root.join(config_file) if config_file
  end

  def self.loops_root
    @@loops_root ||= root.join('app/loops')
  end

  def self.loops_root=(loops_root)
    @@loops_root = root.join(loops_root) if loops_root
  end

  def self.pid_file
    @@pid_file ||= root.join('loops.pid')
  end

  def self.pid_file=(pid_file)
    @@pid_file = root.join(pid_file) if pid_file
  end

  def self.logger
    @@logger ||= ::Loops::Logger.new($stdout)
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.default_logger
    @@default_logger
  end

  def self.default_logger=(logger)
    @@default_logger = logger
  end
end

require File.join(Loops::LIB_ROOT, 'loops/autoload')
