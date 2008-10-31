class Loops::ProcessManager 
  def initialize(config)
    @config = config
    @workers = {}
  end
  
  def start_workers(name, number, &blk)
    raise "Need a worker block!" unless block_given?
    workers = @workers[name] = []
    number.times do |id|
      workers << start_worker(name, &blk)
    end
  end
  
  def start_worker(name, &blk)
    # FIXME: need to make a worker here
  end
  
  def monitor_workers
    # FIXME: need to monitor workers here
  end
end
