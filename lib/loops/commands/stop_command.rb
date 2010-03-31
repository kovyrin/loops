class Loops::Commands::StopCommand < Loops::Command
  def execute
    STDOUT.sync = true
    raise "No pid file or a stale pid file!" unless Loops::Daemonize.check_pid(Loops.pid_file)
    pid = Loops::Daemonize.read_pid(Loops.pid_file)
    print "Killing the process: #{pid}: "

    loop do
      Process.kill('SIGTERM', pid)
      sleep(1)
      break unless Loops::Daemonize.check_pid(Loops.pid_file)
      print(".")
    end

    puts " Done!"
    exit(0)
  end

  def requires_bootstrap?
    false
  end
end