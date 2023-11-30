# frozen_string_literal: true

begin
  require 'stomp'
rescue LoadError
  puts "Can't load stomp gem - all queue loops will be disabled!"
end

require 'timeout'

module Loops
  class Queue < Base
    def self.check_dependencies
      raise 'No stomp gem installed!' unless defined?(Stomp::Client)
    end

    def run
      create_client

      config['queue_name'] ||= "/queue/loops/#{name}"
      config['prefetch_size'] ||= 1
      debug "Subscribing for the queue #{config['queue_name']}..."

      headers = { ack: :client }
      headers['activemq.prefetchSize'] = config['prefetch_size'] if config['prefetch_size']

      @total_served = 0
      @client.subscribe(config['queue_name'], headers) do |msg|
        if config['action_timeout']
          timeout(config['action_timeout']) { process_message(msg) }
        else
          process_message(msg)
        end

        @client.acknowledge(msg)
        @total_served += 1
        if config['max_requests'] && @total_served >= config['max_requests'].to_i
          disconnect_client_and_exit
        end
      rescue Exception => e
        error "Exception from process message! We won't be ACKing the message."
        error "Details: #{e} at #{e.backtrace.first}"
        disconnect_client_and_exit
      end

      @client.join
    rescue Exception => e
      error "Closing queue connection because of exception: #{e} at #{e.backtrace.first}"
      disconnect_client_and_exit
    end

    def process_message(_msg)
      raise 'This method process_message(msg) should be overriden in the loop class!'
    end

    private

    def create_client
      config['port'] ||= config['port'].to_i.zero? ? 61_613 : config['port'].to_i
      config['host'] ||= 'localhost'

      @client = Stomp::Client.open(config['user'], config['password'], config['host'],
                                   config['port'], true)
      setup_signals
    end

    def disconnect_client_and_exit
      debug 'Unsubscribing...'
      begin
        @client.unsubscribe(name)
      rescue StandardError
        nil
      end
      begin
        @client.close
      rescue StandardError
        nil
      end
      exit(0)
    end

    def setup_signals
      Signal.trap('INT') { disconnect_client_and_exit }
      Signal.trap('TERM') { disconnect_client_and_exit }
    end
  end
end
