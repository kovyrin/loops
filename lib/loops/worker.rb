class Worker
  attr_reader :logger
  attr_reader :name

  def initialize(name, logger, &blk)
    raise "Need a worker block!" unless block_given?
    @name = name
    @logger = logger
    
    @pid = nil
    @ppid = $$
    
    @worker_block = blk
  end
  
  def run
    @pid = Kernel.fork(&@worker_block)
  end
  
  def running?
    return false unless @pid
    Process.waitpid(@pid, Process::WNOHANG)
    logger.debug("KILL(#{@pid}) = #{Process.kill(0, @pid)}")
    true
  rescue Exception => e
    logger.error("Exception from kill: #{e} at #{e.backtrace.first}")
    false
  end
end
