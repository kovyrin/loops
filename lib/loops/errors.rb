# frozen_string_literal: true

module Loops
  module Errors
    Error = Class.new(RuntimeError)

    InvalidFrameworkError = Class.new(Error)
    InvalidCommandError   = Class.new(Error)
  end
end
