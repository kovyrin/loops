# Contains information about currently used Loops version.
#
# @example
#   puts "Loops #{Loops::Version::STRING}"
#
module Loops
  module Version
    MAJOR = 2
    MINOR = 0
    PATCH = 8
    BUILD = nil

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end
