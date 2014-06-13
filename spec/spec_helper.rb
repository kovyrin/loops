SPEC_ROOT = File.dirname(__FILE__)
PROJECT_ROOT = File.dirname(SPEC_ROOT)
RAILS_ROOT = File.expand_path(File.join(SPEC_ROOT, 'rails'))

# Load loops library
require File.join(PROJECT_ROOT, 'lib', 'loops')

# Load loops testing harness
require File.join(PROJECT_ROOT, 'lib', 'loops', 'testing')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{SPEC_ROOT}/support/**/*.rb"].each { |f| require(f) }

RSpec.configure do |config|
  # Enable loops testing
  Loops::Testing.enable(config)

  # Mock Framework
  config.mock_with :rspec

  # Raise errors on rspec deprecations
  config.raise_errors_for_deprecations!

  # Enable old and new syntax for expectations and mocks
  config.expect_with :rspec do |c|
    c.syntax = [ :should, :expect ]
  end
  config.mock_with :rspec do |c|
    c.syntax = [ :should, :expect ]
  end
end
