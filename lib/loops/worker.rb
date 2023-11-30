# frozen_string_literal: true

module Loops
  class Worker
    attr_reader :name, :pid, :pm, :index

    def initialize(name, pm, engine, index, &blk)
      raise ArgumentError, 'Need a worker block!' unless block_given?

      @name = name
      @pm = pm
      @engine = engine
      @index = index
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
        GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

        # On Ruby 2.2 we need to make sure all loaded code will end up in the old gen before forking
        # Otherwise, all of it will be marked as private dirty when GC kicks in after the fork.
        # Since there are 3 generations, we just force ruby GC enough times to mark all existing objects as old.
        4.times { GC.start }

        @pid = Kernel.fork do
          @pid = Process.pid
          normal_exit = false
          begin
            $0 = "loop worker: #{@name} ##{@index}"
            @worker_block.call(self)
            normal_exit = true
            exit(0)
          rescue Exception => e
            message = e.is_a?(SystemExit) ? "exit(#{e.status})" : e.to_s
            if e.is_a?(SystemExit) && e.success?
              if normal_exit
                logger.info('Worker finished: normal return')
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
          @worker_block.call(self)
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
          true
        rescue Errno::ESRCH, Errno::ECHILD, Errno::EPERM => e
          logger.error("Exception from kill: #{e} at #{e.backtrace.first}") if verbose
          false
        end
      elsif @engine == 'thread'
        @thread&.alive?
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
        rescue Errno::ESRCH, Errno::ECHILD, Errno::EPERM => e
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
