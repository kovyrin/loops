# Base class for all loop processes.
#
# To create a new loop just inherit this class and override the
# {#run} method (see example below).
#
# In most cases it's a good idea to re-run your loop periodically.
# In this case your process will free all unused memory to the system,
# and all leaked resources (yes, it's real life).
#
# @example
#   class MySuperLoop < Loops::Base
#     def self.check_dependencies
#       gem 'tinder', '=1.3.1'
#     end
#
#     def run
#       1000.times do
#         if shutdown?
#           info("Shutting down!")
#           exit(0)
#         end
#
#         unless item = UploadItems.get_next
#           sleep(config['sleep_time'])
#           next
#         end
#
#         item.perform_upload
#       end
#     end
#   end
#
require 'loops/base_concerns/config_option'

class Loops::Base
  include Loops::BaseConcerns::ConfigOption

  # @return [String]
  #   loop name.
  attr_reader :name

  # @return [Hash<String, Object>]
  #   The hash of loop options from config.
  attr_reader :config

  # Initializes a new instance of loop.
  #
  # @param [Worker] worker
  #   the instance of worker.
  # @param [String] name
  #   the loop name.
  # @param [Hash<String, Object>]
  #   the loop configuration options from the config file.
  #
  def initialize(worker, name, config)
    @worker = worker
    raise ArgumentError, "Invalid worker argument value!" unless worker

    @pm     = worker.pm
    @name   = name
    @config = config
  end

  # Get the logger instance.
  #
  # @return [Logger]
  #   the logger instance.
  #
  def logger
    @pm.logger
  end

  # Get a value indicating whether shutdown is in the progress.
  #
  # Check this flag periodically and if loop is in the shutdown,
  # close all open handlers, update your data, and exit loop as
  # soon as possible to not to loose any sensitive data.
  #
  # @return [Boolean]
  #   a value indicating whether shutdown is in the progress.
  #
  # @example
  #   if shutdown?
  #     info('Shutting down!')
  #     exit(0)
  #   end
  #
  def shutdown?
    @pm.shutdown?
  end

  # Verifies loop dependencies.
  #
  # Override this method if your loop depends on any external
  # libraries, resources, etc. Verify your dependencies here,
  # and raise an exception in case of any trouble to prevent
  # this loop from starting.
  #
  # @example
  #   def self.check_dependencies
  #     gem 'tinder', '=1.3.1'
  #   end
  #
  def self.check_dependencies
  end

  # A loop entry point. Should be overridden in descendants.
  #
  def run
    raise 'Generic loop has nothing to do'
  end

  # Proxy logger calls to our logger
  [ :debug, :info, :warn, :error, :fatal ].each do |meth_name|
    class_eval <<-EVAL, __FILE__, __LINE__ + 1
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
    raise ArgumentError, "No block given!" unless block_given?
    loop do
      yield
      if shutdown?
        debug("Shutdown: stopping the loop")
        break
      end
      sleep(seconds.to_i)
    end
  end
end
