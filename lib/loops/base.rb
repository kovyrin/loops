class Loops::Base
  attr_accessor :name, :config, :logger
  
  def initialize(logger)
    self.logger = logger
  end

  # has no dependencies yet
  def self.check_dependencies; end
  
  # Proxy logger calls to our logger
  [ :debug, :error, :fatal, :info, :warn ].each do |meth_name|
    class_eval <<-EVAL
      def #{meth_name}(message)
        logger.#{meth_name}("\#{Time.now}: loop[\#{name}/\#{Process.pid}]: \#{message}")
      end
    EVAL
  end
  
  def with_period_of(seconds)
    raise "No block given!" unless block_given?
    EM.add_periodic_timer(seconds) do
      yield
    end
  end
end
