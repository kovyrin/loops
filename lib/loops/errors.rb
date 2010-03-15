module Loops::Errors
  Error = Class.new(RuntimeError)

  InvalidFrameworkError = Class.new(Error)
end