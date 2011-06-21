require 'rake'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc 'Test the loops plugin.'
RSpec::Core::RakeTask.new

require 'yard'
YARD::Rake::YardocTask.new(:yard) do |t|
  t.options = ['--title', 'Loops Documentation']
  if ENV['PRIVATE']
    t.options.concat ['--protected', '--private']
  else
    t.options.concat ['--protected', '--no-private']
  end
end
