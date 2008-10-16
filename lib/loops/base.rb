class Loops::Base
  attr_accessor :name
  attr_accessor :config
  
  def log(*keys)
    puts "#{Time.now} [#{name}/#{Process.pid}]: #{keys.join(' ')}"
  end
  
  def with_period_of(seconds)
    raise "No block given!" unless block_given?
    EM.add_periodic_timer(seconds) do
      yield
    end
  end
end
