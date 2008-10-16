# Simple loop with its own custom run method
#
# Does nothing aside from printing loop's name, pid and current time every second
#
class TimeLoop < Loops::Base
  def run
    EM.add_periodic_timer(1) do
      log(Time.now)
      sleep(5)
    end
  end
end
