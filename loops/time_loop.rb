# Simple loop with its own custom run method
#
# Does nothing aside from printing loop's name, pid and current time every second
#
class TimeLoop < Loops::Base
  def run
    loop do
      puts "#{name}(#{Process.pid}): #{Time.now.to_s}"
      sleep(1)
    end
  end
end
