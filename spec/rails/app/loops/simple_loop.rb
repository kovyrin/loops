class SimpleLoop < Loops::Base
  def run
    info "Do not show this in log"
    error "Woohoo! I'm in the loop log"
  end
end
