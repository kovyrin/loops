class QueueLoop < Loops::Queue
  def process_message(message)
    log "Received a message: #{message.body}"
    log "sleeping..."
    sleep(0.5 + rand(10) / 10.0)
    log "done..."
  end
end
