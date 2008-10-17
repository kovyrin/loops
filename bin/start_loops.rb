#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'eventmachine'
require 'activesupport'

LOOPS_ROOT = File.dirname(__FILE__) + "/.."
LOOPS_CONFIG_FILE = LOOPS_ROOT + "/config/loops.yml"

$:.unshift(LOOPS_ROOT + '/lib')
require 'ext/em'
require 'loops'

puts "Loading config..."
Loops.load_config(LOOPS_CONFIG_FILE)

puts "Starting workers"
Loops.start_loops!
