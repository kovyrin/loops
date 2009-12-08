class Loops::Base
  attr_accessor :name, :config, :logger

  def initialize(logger)
    self.logger = logger
  end

  # has no dependencies yet
  def self.check_dependencies; end

  # Proxy logger calls to our logger
  [ :debug, :error, :fatal, :info, :warn ].each do |meth_name|
    class_eval <<-EVAL, __FILE__, __LINE__
      def #{meth_name}(message)
        logger.#{meth_name}("loop[\#{name}/\#{Process.pid}]: \#{message}")
      end
    EVAL
  end

  def with_lock(entity_ids, loop_id, timeout, entity_name = '', &block)
    entity_name = 'item' if entity_name.to_s.empty?
    entity_ids = [entity_ids] unless Array === entity_ids

    entity_ids.each do |entity_id|
      debug("Locking #{entity_name} #{entity_id}")
      lock = LoopLock.lock(:entity_id => entity_id, :loop => loop_id.to_s, :timeout => timeout)
      unless lock
        warn("Race condition detected for the #{entity_name}: #{entity_id}. Skipping the item.")
        next
      end

      begin
        result = if block.arity == 1
          yield entity_id
        else
          yield
        end
        return result
      ensure
        debug("Unlocking #{entity_name} #{entity_id}")
        LoopLock.unlock(:entity_id => entity_id, :loop => loop_id.to_s)
      end
    end
  end

  def with_period_of(seconds)
    raise "No block given!" unless block_given?
    loop do
      yield
      sleep(seconds)
    end
  end
end
