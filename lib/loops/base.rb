class Loops::Base
  attr_accessor :name
  attr_accessor :config
  
  def log(*keys)
    puts "#{Time.now} [#{name}/#{Process.pid}]: #{keys.join(' ')}"
  end
end
