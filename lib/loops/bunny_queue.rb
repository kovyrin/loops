begin
  require 'bunny'
rescue LoadError
  puts "Can't load bunny gem - all queue loops will be disabled!"
end

require 'timeout'

module Loops
  class BunnyQueue < Base
    def self.check_dependencies
      raise "No bunny gem installed!" unless defined?(Bunny)
    end

    def run
      create_client

      config['queue_name'] ||= "/queue/loops/#{name}"
      config['ack']        ||= false
      debug "Client created" if @client
      debug "Subscribing for the queue #{config['queue_name']}..."

      @total_served = 0
      @channel ||= @client.create_channel
      debug "Channel created" if @channel
      @queue   ||= @channel.queue(config['queue_name'])
      debug "Queue created" if @queue

      @queue.subscribe(:ack => config['ack'], :block => true) do |delivery_info, properties, payload|
        begin
          process_message(delivery_info, properties, payload)

          @channel.ack(delivery_info.delivery_tag, false) if config['ack']
          @total_served += 1
          if config['max_requests'] && @total_served >= config['max_requests'].to_i
            disconnect_client_and_exit
          end
        rescue => e
          error "Exception from process message! We won't be ACKing the message."
          error "Details: #{e} at #{e.backtrace.first}"
          disconnect_client_and_exit
        end
      end
    rescue => e
      error "Closing queue connection because of exception: #{e} at #{e.backtrace.first}"
      disconnect_client_and_exit
    end

    def process_message(delivery_info, properties, payload)
      raise "This method process_message(msg) should be overriden in the loop class!"
    end

  private

    def create_client
      debug "Create Bunny client..."
      config['uri'] ||= 'amqp://127.0.0.1:5672'

      @client = Bunny.new(config['uri'])
      @client.start
    end

    def disconnect_client_and_exit
      debug "Unsubscribing..."
      @client.close
      exit(0)
    end
  end
end
