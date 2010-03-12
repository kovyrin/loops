require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = 'loops'
    gemspec.summary     = 'Simple background loops framework for ruby'
    gemspec.description = 'Loops is a small and lightweight framework for Ruby on Rails, Merb and other ruby frameworks created to support simple background loops in your application which are usually used to do some background data processing on your servers (queue workers, batch tasks processors, etc).'
    gemspec.email       = 'alexey@kovyrin.net'
    gemspec.homepage    = 'http://github.com/kovyrin/loops'
    gemspec.authors     = ['Alexey Kovyrin', 'Dmytro Shteflyuk']
    gemspec.files.include ['lib/**/*']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler not available. Install it with: sudo gem install jeweler'
end

begin
  require 'spec/rake/spectask'

  desc 'Default: run unit tests.'
  task :default => :spec

  desc 'Test the loops plugin.'
  Spec::Rake::SpecTask.new(:spec) do |t|
    t.libs << 'lib'
    t.pattern = 'spec/**/*_spec.rb'
    t.verbose = true
    t.spec_opts = ['-cfs']
  end
rescue LoadError
  puts 'RSpec not available. Install it with: sudo gem install rspec'
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new(:yard) do |t|
    t.options = ['--title', 'Loops Documentation']
    if ENV['PRIVATE']
      t.options.concat ['--protected', '--private']
    else
      t.options.concat ['--protected', '--no-private']
    end
  end
rescue LoadError
  puts 'Yard not available. Install it with: sudo gem install yard'
end
