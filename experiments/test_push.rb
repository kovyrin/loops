#!/usr/bin/env ruby

require 'rubygems'
#require 'mq'
require 'stomp'

=begin
$:.unshift File.dirname(__FILE__) + '/lib/qpid'
require 'qpid'

specxml = File.dirname(__FILE__) + '/specification/amqp0-8.xml'

client = Qpid::Client.new("127.0.0.1", 5672, spec = Spec.load(specxml))
client.start({ "LOGIN" => "guest", "PASSWORD" => "guest" })

ch = client.channel(1)
ch.channel_open()

headers = { 'sent' => Time.now.to_i }
content = Qpid::Content.new({ :headers => headers }, "hello world!")

ch.basic_publish(:content => content, :exchange => 'seo-loop-docs')
=end

=begin
EM.run do
  amq = MQ.direct('seo-loop-docs-exchange', :durable => true)
  
  1.times { |i| amq.publish('!!!! ping %d' % [i], :persistent => true) }
  AMQP.stop { EM.stop }
end
=end

=begin
QUEUE_NAME = "loops_queue_seo_loop"

EM.run do
  amq = MQ.queue(QUEUE_NAME, :durable => true)
  
  100000.times { |i| 
    amq.publish('Fucking Ping %d!' % [i], :persistent => true)
  }

  AMQP.stop { EM.stop }
end
=end

=begin
EM.run {
  rpc = MQ.rpc('seo-loop')
  
  100.times { |i|
    rpc.process_document("hello #{i}") do
      puts "Processed document #{i}"
    end
  }
}
=end

client = Stomp::Client.open "stomp://localhost:61613"

1.times do |i|
  client.send('/queue/analytics/hits', "hello world #{i}", :persistent => true)
end

client.close

