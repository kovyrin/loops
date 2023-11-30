# frozen_string_literal: true

require 'English'
module Loops
  module Daemonize
    def self.read_pid(pid_file)
      File.open(pid_file) do |f|
        f.gets.to_i
      end
    rescue Errno::ENOENT
      0
    end

    def self.check_pid(pid_file)
      pid = read_pid(pid_file)
      return false if pid.zero?

      if defined?(::JRuby)
        system "kill -0 #{pid} &> /dev/null"
        return $CHILD_STATUS == 0
      else
        Process.kill(0, pid)
      end
      true
    rescue Errno::ESRCH, Errno::ECHILD, Errno::EPERM
      false
    end

    def self.create_pid(pid_file)
      if File.exist?(pid_file)
        puts "Pid file #{pid_file} exists! Checking the process..."
        if check_pid(pid_file)
          puts "Can't create new pid file because another process is running!"
          return false
        end
        puts 'Stale pid file! Removing...'
        File.delete(pid_file)
      end

      File.open(pid_file, 'w') do |f|
        f.puts(Process.pid)
      end

      true
    end

    def self.daemonize(app_name)
      if defined?(::JRuby)
        puts 'WARNING: daemonize method is not implemented for JRuby (yet), please consider using nohup.'
        return
      end

      fork && exit # Fork and exit from the parent

      # Detach from the controlling terminal
      unless (sess_id = Process.setsid)
        raise Daemons.RuntimeException, 'cannot detach from controlling terminal'
      end

      # Prevent the possibility of acquiring a controlling terminal
      trap 'SIGHUP', 'IGNORE'
      exit if fork

      $0 = app_name if app_name

      Dir.chdir(Loops.root) # Make sure we're in the working directory
      File.umask(0o000) # Insure sensible umask

      sess_id
    end
  end
end
