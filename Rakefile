# frozen_string_literal: true

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task test: :spec
task default: :spec

require 'yard'
YARD::Rake::YardocTask.new(:yard) do |t|
  t.options = ['--title', 'Loops Documentation']
  if ENV['PRIVATE']
    t.options.push '--protected', '--private'
  else
    t.options.push '--protected', '--no-private'
  end
end
