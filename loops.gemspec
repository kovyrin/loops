# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'loops/version'

Gem::Specification.new do |s|
  s.name         = 'loops'
  s.version      = Loops::Version::STRING
  s.platform     = Gem::Platform::RUBY
  s.authors      = ['Oleksiy Kovyrin', 'Dmytro Shteflyuk']
  s.email        = 'oleksiy@kovyrin.net'
  s.homepage     = 'https://github.com/kovyrin/loops'
  s.summary      = 'Simple background loops framework for ruby'
  s.description  = <<~DESC
    Loops is a small and lightweight framework for Ruby created to support simple
    background jobs in your application which are typically used to do some
    periodic data processing on your servers (queue workers, batch tasks processors, etc).
  DESC
  s.rdoc_options = ['--charset=UTF-8']

  s.files            = `git ls-files`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths    = ['lib']
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.metadata['rubygems_mfa_required'] = 'true'
end
