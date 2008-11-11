class Worker
  attr_reader :logger
  attr_reader :name
  attr_reader :pid

  def initialize(name, logger, &blk)
    raise "Need a worker block!" unless block_given?
    @name = name
    @logger = logger
    
    @pid = nil
    @ppid = $$
    
    @worker_block = blk
    @shutdown = false
  end
  
  def shutdown?
    @shutdown
  end
  
  def run
    return if shutdown?
    @pid = Kernel.fork do
      $0 = "loop worker: #{@name}\0"
      @pid = Process.pid
      @worker_block.call
    end
  rescue Exception => e
    logger.error("Exception from worker: #{e} at #{e.backtrace.first}")
  end
  
  def running?(verbose = false)
    return false if shutdown?
    return false unless @pid
    Process.waitpid(@pid, Process::WNOHANG)
    res = Process.kill(0, @pid)
    logger.debug("KILL(#{@pid}) = #{res}") if verbose
    true
  rescue Exception => e
    logger.error("Exception from kill: #{e} at #{e.backtrace.first}") if verbose
    false
  end
  
  def stop(force = false)
    @shutdown = true
    sig = force ? 'SIGKILL' : 'SIGTERM'
    logger.debug("Sending #{sig} to ##{@pid}")
    Process.kill(sig, @pid)
  rescue Exception => e
    logger.error("Exception from kill: #{e} at #{e.backtrace.first}")
  end
end
