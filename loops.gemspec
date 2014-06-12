# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'loops/version'

Gem::Specification.new do |s|
  s.name         = 'loops'
  s.version      = Loops::Version::STRING
  s.platform     = Gem::Platform::RUBY
  s.authors      = [ 'Oleksiy Kovyrin', 'Dmytro Shteflyuk' ]
  s.email        = %q{alexey@kovyrin.net}
  s.homepage     = %q{http://github.com/kovyrin/loops}
  s.summary      = %q{Simple background loops framework for ruby}
  s.description  = %q{Loops is a small and lightweight framework for Ruby on Rails, Merb and other ruby frameworks created to support simple background loops in your application which are usually used to do some background data processing on your servers (queue workers, batch tasks processors, etc).}
  s.rdoc_options = ['--charset=UTF-8']

  s.add_development_dependency 'rspec', ' ~> 3.0.0'
  s.add_development_dependency 'yard'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths    = ['lib']
  s.extra_rdoc_files = ['LICENSE', 'README.rdoc']
end
