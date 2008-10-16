class Loops::Queue < Loops::Base
  def run
#    AMQP.logging = true
    queue_processor = Proc.new do |h, m|
      opts = {}

      if (m == :empty || !m)
        opts[:delay] = config['poll_period'] || 1
      else
        begin
          process_message(m)
        rescue
          puts "Exception from process message! You should push the message back!"
        end
      end

      queue.pop(opts, &queue_processor)
    end

    queue.pop(&queue_processor)
  end
  
protected

  def push_back(message)
    puts "Pushing a message back to the queue"
    queue.publish(message)
  end

private

  def queue
    config['queue_name'] ||= "loops_queue_#{name}"
    MQ.queue(config['queue_name'], :durable => true)
  end

end