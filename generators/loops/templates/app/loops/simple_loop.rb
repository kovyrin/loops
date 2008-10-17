# Simple loop with its own custom run method
#
# Does nothing aside from printing loop's name, pid and current time every second
#
class TimeLoop < Loops::Base
  def run
    with_period_of(1) do
      debug(Time.now)
      sleep(5)
    end
  end
end
