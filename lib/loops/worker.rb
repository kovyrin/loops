class Worker
  attr_reader :logger

  def initialize(name, logger, &blk)
    raise "Need a worker block!" unless block_given?
    @name = name
    @logger = logger
    
    @pid = nil
    @ppid = $$
    
    worker_block = &blk
  end
  
  def run
    @pid = Kernel.fork(&blk)
  end
  
  def running?
    Process.kill(0, @pid) == 0
  end
end
