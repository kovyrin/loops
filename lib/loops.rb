require 'yaml'
require 'erb'
require 'pathname'

module Loops
  LIB_ROOT = File.expand_path(File.dirname(__FILE__))
  BINARY   = File.expand_path(File.join(LIB_ROOT, '../bin/loops'))

  def self.root
    @@root
  end

  def self.root=(path)
    @@root = Pathname.new(path)
  end

  def self.default_logger
    @@default_logger
  end

  def self.default_logger=(logger)
    @@default_logger = logger
  end

  def self.config_file
    root + 'config/loops.yml'
  end
end

require File.join(Loops::LIB_ROOT, 'loops/autoload')
