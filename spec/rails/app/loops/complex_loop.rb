class ComplexLoop < Loops::Base
  def run
    loop do
      if shutdown?
        info("Shutting down!")
        exit(0)
      end

      info("ping")
      sleep(1)
    end
  end
end
