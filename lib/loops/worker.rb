class Worker
  attr_reader :logger

  def initialize(name, logger, &blk)
    raise "Need a worker block!" unless block_given?
    @name = name
    @logger = logger
    worker_block = &blk
  end
  
  def run
    # FIXME: Add worker running code here
  end
  
  def running?
    # FIXME: Add worker health checks here
  end
end
