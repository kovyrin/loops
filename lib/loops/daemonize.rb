class Loops
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
      Process.kill(0, pid)
      true
    rescue Exception => e
      false
    end
    
    def self.create_pid(pid_file)
      if File.exist?(pid_file)
        puts "Pid file #{pid_file} exists! Checking the process..."
        if check_pid(pid_file)
          puts "Can't create new pid file because another process is runnig!"
          return false
        end
        puts "Stale pid file! Removing..."
        File.delete(pid_file)
      end
      
      puts "Creating pid file..."
      File.open(pid_file, 'w') do |f|
        f.puts(Process.pid)
      end

      return true
    end
    
    def self.daemonize(app_name)
      srand # Split rand streams between spawning and daemonized process
      fork && exit # Fork and exit from the parent

      # Detach from the controlling terminal
      unless sess_id = Process.setsid
        raise Daemons.RuntimeException.new('cannot detach from controlling terminal')
      end

      # Prevent the possibility of acquiring a controlling terminal
      trap 'SIGHUP', 'IGNORE'
      exit if pid = fork

      $0 = app_name if app_name

      Dir.chdir(Rails.root) # Make sure we're in the working directory
      File.umask(0000) # Insure sensible umask
 
#      redirect_io
      
      return sess_id
    end
    
    def self.redirect_io
      [ STDIN, STDOUT, STDERR ].each do |io|
        begin
          io.reopen('/dev/null')
        rescue ::Exception
        end
      end
    end
    
  end
end