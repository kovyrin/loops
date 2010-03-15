require 'yaml'
require 'erb'
require 'pathname'

module Loops
  # @return [String]
  #   a full path to the loops "lib" directory.
  LIB_ROOT = File.expand_path(File.dirname(__FILE__)) unless const_defined?('LIB_ROOT')
  # @return [String]
  #   a full path to the loops binary file.
  BINARY   = File.expand_path(File.join(LIB_ROOT, '../bin/loops')) unless const_defined?('BINARY')

  # Loops root directory.
  #
  # Usually it is initialized with framework's root dir (RAILS_ROOT or MERB_ROOT),
  # but you can specify another directory using command line arguments.
  #
  # Loops current directory will is set to this value (chdir).
  #
  # @return [Pathname, nil]
  #   the loops root directory.
  #
  def self.root
    @@root
  end

  # Set loops root directory.
  #
  # This is internal method used to set the loops root directory.
  #
  # @param [String] path
  #   the absolute path of the loops root directory.
  # @return [Pathname]
  #   the loops root directory.
  #
  # @private
  #
  def self.root=(path)
    @@root = Pathname.new(path).realpath
  end

  # Get loops config file full path.
  #
  # @return [Pathname]
  #   the loops config file path.
  #
  def self.config_file
    @@config_file ||= root.join('config/loops.yml')
  end

  # Set loops config file path.
  #
  # This is internal method used to set the loops config file path.
  #
  # @param [String] path
  #   the absolute or relative to the loops root path of the loops
  #   config file.
  # @return [Pathname]
  #   the loops config file path.
  #
  # @private
  #
  def self.config_file=(config_file)
    @@config_file = root.join(config_file) if config_file
  end

  # Get directory containing loops classes.
  #
  # @return [Pathname]
  #   the loops directory path.
  #
  def self.loops_root
    @@loops_root ||= root.join('app/loops')
  end

  # Set loops classes directory path.
  #
  # This is internal method used to set directory where loops classes
  # will be searched.
  #
  # @param [String] path
  #   the absolute or relative to the loops classes directory.
  # @return [Pathname]
  #   the loops classes directory path.
  #
  # @private
  #
  def self.loops_root=(loops_root)
    @@loops_root = root.join(loops_root) if loops_root
  end

  # Get the loops monitor process pid file path.
  #
  # @return [Pathname]
  #   the loops monitor process pid file path.
  #
  def self.pid_file
    @@pid_file ||= root.join('loops.pid')
  end

  # Set the loops monitor pid file path.
  #
  # This is internal method used to set the loops monitor pid file path.
  #
  # @param [String] path
  #   the absolute or relative to the loops monitor pid file.
  # @return [Pathname]
  #   the loops monitor pid file path.
  #
  # @private
  #
  def self.pid_file=(pid_file)
    @@pid_file = root.join(pid_file) if pid_file
  end

  # Get the current loops logger.
  #
  # There are two contexts where different devices (usually) will be
  # configured for this logger instance:
  #
  # 1. In context of loops monitor logger device will be retrieved from
  #    the global section of the loops config file, or STDOUT when it
  #    was not configured.
  # 2. In context of loop proccess logger device will be configured
  #    based on logger value of the particular loop section in the config
  #    file.
  #
  # @example Put all Rails logging into the loop log file (add this to the environment.rb)
  #   Rails.logger = Loops.logger
  #
  # @return [Loops::Logger]
  #   the current loops logger instance.
  #
  def self.logger
    @@logger ||= ::Loops::Logger.new($stdout)
  end

  # Set the current loops logger.
  #
  def self.logger=(logger)
    @@logger = logger
  end

  # Get the current framework's default logger.
  #
  # @return [Logger]
  #   the default logger for currently used framework.
  #
  def self.default_logger
    @@default_logger
  end

  # Set the current framework's default logger.
  #
  # @param [Logger] logger
  #   the default logger for currently used framework.
  # @return [Logger]
  #   the default logger for currently used framework.
  #
  # @private
  #
  def self.default_logger=(logger)
    @@default_logger = logger
  end
end

require File.join(Loops::LIB_ROOT, 'loops/autoload')
