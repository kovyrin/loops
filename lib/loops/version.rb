# Contains information about currently used Loops version.
#
# @example
#   puts "Loops #{Loops::Version::STRING}"
#
module Loops
  module Version
    MAJOR = 2
    MINOR = 1
    PATCH = 0
    BUILD = 'dev'

    STRING = [ MAJOR, MINOR, PATCH, BUILD ].compact.join('.')
  end
end
