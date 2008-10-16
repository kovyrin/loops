require 'stomp'
require 'timeout'

class Loops::Queue < Loops::Base
  def run
    create_client
    
    config['queue_name'] ||= "/queue/loops/#{name}"
    config['prefetch_size'] ||= 1
    log "Subscribing for the queue #{config['queue_name']}..."
    
    headers = { :ack => :client }
    headers["activemq.prefetchSize"] = config['prefetch_size'] if config['prefetch_size']
    
    @total_served = 0
    @client.subscribe(config['queue_name'], headers) do |msg|
      begin
        if config['action_timeout']
          timeout(config['action_timeout']) { process_message(msg) }
        else
          process_message(msg)
        end
        
        @client.acknowledge(msg)
        @total_served += 1
        if config['max_requests'] && @total_served >= config['max_requests'].to_i
          disconnect_client
          exit(0)
        end
      rescue Exception => e
        log "Exception from process message! We won't be ACKing the message."
        log "Details: #{e} at #{e.backtrace.first}"
        disconnect_client
        exit(0)
      end
    end
    
    @client.join
  rescue Exception => e
    log "Closing queue connection because of exception: #{e} at #{e.backtrace.first}"
    disconnect_client
    exit(0)
  end

  def process_message(msg)
    raise "This method process_message(msg) should be overriden in the loop class!"
  end

private

  def create_client
    config['port'] ||= config['port'].to_i == 0 ? 61613 : config['port'].to_i
    config['host'] ||= 'localhost'
    
    @client = Stomp::Client.open(config['user'], config['password'], config['host'], config['port'], true)
    setup_signals
  end
  
  def disconnect_client
    log "Unsubscribing..."
    @client.unsubscribe(name)
    @client.close()
  end

  def setup_signals
    Signal.trap('INT') { disconnect_client }
    Signal.trap('TERM') { disconnect_client }    
  end

end
