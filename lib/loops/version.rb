# Contains information about currently used Loops version.
#
# @example
#   puts "Loops #{Loops::Version}"
#
class Loops::Version
  # @return [Hash<Symbol, Integer>]
  #   a +Hash+ containing major, minor, and patch version parts.
  CURRENT = YAML.load_file(File.join(Loops::LIB_ROOT, '../VERSION.yml'))

  # @return [Integer]
  #   a major part of the Loops version.
  MAJOR = CURRENT[:major]
  # @return [Integer]
  #   a minor part of the Loops version.
  MINOR = CURRENT[:minor]
  # @return [Integer]
  #   a patch part of the Loops version.
  PATCH = CURRENT[:patch]

  # @return [String]
  #   a string representation of the Loops version.
  STRING = "%d.%d.%d" % [MAJOR, MINOR, PATCH]

  # @return [String]
  #   a string representation of the Loops version.
  #
  def self.to_s
    STRING
  end
end
