class SeoLoop < Loops::Queue
  def process_message(message)
    puts "Received a message: #{message.inspect}"
  end
end
