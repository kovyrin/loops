class SeoLoop < Loops::Base
  def run
    loop do
      puts "#{name}(#{Process.pid}): #{Time.now.to_s}"
      sleep(1)
    end
  end
end

dsfsdf