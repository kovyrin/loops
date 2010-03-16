class ComplexLoop < Loops::Base
  def run
    with_period_of(1.second) do
      if shutdown?
        info("Shutting down!")
        return # exit the loop
      end

      info("ping")
    end
  end
end
