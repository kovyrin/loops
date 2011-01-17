module Ext
  module Loops
    class Amqp < Base

      def self.check_dependencies
        gem 'tmm1-amqp'
      end

      def subscribes
        raise "This method 'subscribes' should be overriden in the loop class!"
      end

      def run
        setup_signals
        subscribes
        raise 'No subscribe given!' unless @subscribes || @subscribes.any?
        AMQP.start(connection_params) do
          @subscribes.each do |block|
            block.call
          end
        end
      rescue Exception => e
        error "Closing queue connection because of exception: #{e} at #{e.backtrace.first}"
        disconnect_client_and_exit
      end

      private

      def subscribe(handler, options)
        raise ArgumentError, "No queue name (:queue_name) given!" unless options[:queue_name]
        raise ArgumentError, "No exchange name (:exchange_name) given!" unless options[:exchange_name]

        options[:prefetch] ||= 1
        options[:ack] ||= true
        options[:type] ||= :topic
        options[:sleep] ||= 1

        options[:exchange] ||= {}
        options[:exchange][:durable] ||= false
        options[:queue] ||= {}
        options[:queue][:durable] ||= false
        options[:bind] ||= {}


        proc = Proc.new do
          mq = MQ.new
          mq.prefetch(options[:prefetch])
          exchange = mq.__send__ options[:type], options[:exchange_name], options[:exchange]

          debug "Subscribing for the queue #{options[:queue_name]}..."

          mq.queue(options[:queue_name], options[:queue]).
            bind(exchange, options[:bind]).
            subscribe(:ack => options[:ack]) do |header, msg|
            begin
              handler.call(msg, header)
              header.ack if options[:ack] #TODO
            rescue Exception => e
              error "Exception from process message! We won't be ACKing the message."
              error "Details: #{e} at #{e.backtrace.first}"
              disconnect_client_and_exit
            end
          end
        end

        debug "Adding proc to @subscribes"
        @subscribes ||= []
        @subscribes << proc
      end

      def disconnect_client_and_exit
        debug "Close..."
        AMQP.stop{ EM.stop }
        exit(0)
      end

      def connection_params
        connection_params ||= {}
        connection_params[:host] = config["host"] || 'localhost'
        connection_params[:user] = config["user"] || 'guest'
        connection_params[:pass] = config["pass"] || 'guest'
        connection_params[:vhost] = config["vhost"] || '/'
        connection_params[:timeout] = config["timeout"] || nil
        connection_params[:logging] = config["logging"] || false

        connection_params
      end

      def setup_signals
        Signal.trap('INT') { disconnect_client_and_exit }
        Signal.trap('TERM') { disconnect_client_and_exit }
      end
    end
  end
end