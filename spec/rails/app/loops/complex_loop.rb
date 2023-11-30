# frozen_string_literal: true

class ComplexLoop < Loops::Base
  def run
    with_period_of(1) do
      if shutdown?
        info('Shutting down!')
        return # exit the loop
      end

      info('ping')
    end
  end
end
