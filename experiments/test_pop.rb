#!/usr/bin/env ruby

require 'rubygems'
require 'mq'
require 'stomp'
require 'pp'

# For ack to work appropriatly you must shutdown AMQP gracefully,
# otherwise all items in your queue will be returned
=begin
Signal.trap('INT') { AMQP.stop{ EM.stop } }
Signal.trap('TERM'){ AMQP.stop{ EM.stop } }

EM.run do
  AMQP.logging = true
  
  amq = MQ.new
  amq.queue('seo-loop-docs-queue', :durable => true).
      bind(MQ.direct('seo-loop-docs-exchange', :durable => true)).
      subscribe(:no_ack => false) do |msg|
        begin
          puts "Started processing..."
          sleep(1)
          p msg
        end
      end
end
=end

QUEUE_NAME = "test1"

EM.run do
  AMQP.logging = true
  queue = MQ.queue(QUEUE_NAME, :durable => true) 
  
  queue_processor = Proc.new do |h, m|
    opts = {}

    if (m == :empty || !m)
      puts "Empty reqponse..."
      opts[:delay] = 1
    else
      puts "Started processing..."
      sleep(1)
      pp m
    end
    
    queue.pop(opts, &queue_processor)
  end

  queue.pop(&queue_processor)
end

=begin
EM.run {
  class SeoLoop
    def process_document(doc)
      puts "Processing doc #{doc}"
      sleep(1)
      puts "Done #{doc}"
    end
  end
  
  MQ.rpc("seo-loop", SeoLoop.new)
}
=end

=begin
puts "Connecting..."
client = Stomp::Client.open "stomp://localhost:61613"

puts "Subscribing..."
client.subscribe('/queue/analytics/hits', :ack => :client, "activemq.prefetchSize" => 1) do |msg|
  puts "Received message #{msg.inspect}"
  sleep 1
  client.acknowledge(msg)
  puts "Finished with message #{msg.inspect}"
end

puts "loop..."

cnt = 0
while true do
  sleep(0.1)
  print "."
  cnt += 1
  puts "" if cnt % 100 == 0
end
=end