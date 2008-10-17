class QueueLoop < Loops::Queue
  def process_message(message)
    debug "Received a message: #{message.body}"
    debug "sleeping..."
    sleep(0.5 + rand(10) / 10.0)
    debug "done..."
  end
end
