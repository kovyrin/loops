#!/usr/bin/env ruby

require 'optparse'
require File.dirname(__FILE__) + '/../config/boot'
require File.dirname(__FILE__) + '/../config/environment'

$LOAD_PATH.unshift("vendor/plugins/loops/lib")

LOOPS_ROOT = Rails.root
LOOPS_CONFIG_FILE = LOOPS_ROOT + "/config/loops.yml"

require 'loops'

options = { :daemonize => false, :loops => [], :all_loops => false, :list_loops => false }
opts = OptionParser.new do |opt|
  opt.banner = "Usage: loops [options]"
  opt.separator ""
  opt.separator "Specific options:"

  opt.on('-d', '--daemonize', 'Daemonize when all loops started.') { |v| options[:daemonize] = v }
  opt.on("--loop=loop_name", 'Start specified loop(s) only') { |v| options[:loops] << v }
  opt.on('-a', '--all', 'Start all loops') { |v| options[:all_loops] = v }
  opt.on('-l', '--list', 'Shows all available loops with their options') { |v| options[:list_loops] = v }

  opt.on_tail("-h", "--help", "Show this message") do
    puts(opt)
    exit(0)
  end

  opt.parse!(ARGV)
end

puts "Loading config..."
Loops.load_config(LOOPS_CONFIG_FILE)

# List loops if requested
if options[:list_loops]
  puts "Available loops:"
  Loops.loops_config.each do |name, config|
    puts "Loop: #{name}" + (config['disabled'] ? ' (disabled)' : '')
    config.each do |k,v|
      puts " - #{k}: #{v}"
    end
  end
  puts
  exit(0)
end

# Ignore --loop options if --all parameter passed
options[:loops] = :all if options[:all_loops]

# Check what loops we gonna run
raise "No loops to run!" if options[:loops] == []

puts "Starting workers"
Loops.start_loops!(options[:loops])

# TODO: Make it daemonize if options[:daemonize]
