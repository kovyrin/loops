module Loops
  class Worker
    attr_reader :name
    attr_reader :pid

    def initialize(name, pm, engine, &blk)
      raise ArgumentError, "Need a worker block!" unless block_given?

      @name = name
      @pm = pm
      @engine = engine
      @worker_block = blk
    end

    def logger
      @pm.logger
    end

    def shutdown?
      @pm.shutdown?
    end

    def run
      return if shutdown?
      if @engine == 'fork'
        # Enable COW-friendly garbage collector in Ruby Enterprise Edition
        # See http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow for more details
        if GC.respond_to?(:copy_on_write_friendly=)
          GC.copy_on_write_friendly = true
        end

        @pid = Kernel.fork do
          @pid = Process.pid
          normal_exit = false
          begin
            $0 = "loop worker: #{@name}\0"
            @worker_block.call
            normal_exit = true
            exit(0)
          rescue Exception => e
            message = SystemExit === e ? "exit(#{e.status})" : e.to_s
            if SystemExit === e and e.success?
              if normal_exit
                logger.info("Worker finished: normal return")
              else
                logger.info("Worker exited: #{message} at #{e.backtrace.first}")
              end
            else
              logger.fatal("Worker exited with error: #{message}\n  #{e.backtrace.join("\n  ")}")
            end
            logger.fatal("Terminating #{@name} worker: #{@pid}")
          end
        end
      elsif @engine == 'thread'
        @thread = Thread.start do
          @worker_block.call
        end
      else
        raise ArgumentError, "Invalid engine name: #{@engine}"
      end
    rescue Exception => e
      logger.error("Exception from worker: #{e} at #{e.backtrace.first}")
    end

    def running?(verbose = false)
      if @engine == 'fork'
        return false unless @pid
        begin
          Process.waitpid(@pid, Process::WNOHANG)
          res = Process.kill(0, @pid)
          logger.debug("KILL(#{@pid}) = #{res}") if verbose
          return true
        rescue Errno::ESRCH, Errno::ECHILD, Errno::EPERM => e
          logger.error("Exception from kill: #{e} at #{e.backtrace.first}") if verbose
          return false
        end
      elsif @engine == 'thread'
        @thread && @thread.alive?
      else
        raise ArgumentError, "Invalid engine name: #{@engine}"
      end
    end

    def stop(force = false)
      if @engine == 'fork'
        begin
          sig = force ? 'SIGKILL' : 'SIGTERM'
          logger.debug("Sending #{sig} to ##{@pid}")
          Process.kill(sig, @pid)
        rescue Errno::ESRCH, Errno::ECHILD, Errno::EPERM=> e
          logger.error("Exception from kill: #{e} at #{e.backtrace.first}")
        end
      elsif @engine == 'thread'
        force && !defined?(::JRuby) ? @thread.kill! : @thread.kill
      else
        raise ArgumentError, "Invalid engine name: #{@engine}"
      end
    end
  end
end
