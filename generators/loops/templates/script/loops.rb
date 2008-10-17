#!/usr/bin/env ruby

LOOPS_ROOT = RAILS_ROOT
LOOPS_CONFIG_FILE = LOOPS_ROOT + "/config/loops.yml"

require 'loops/ext/em'
require 'loops/ext/emfork'
require 'loops/loops'

puts "Loading config..."
Loops.load_config(LOOPS_CONFIG_FILE)

puts "Starting workers"
Loops.start_loops!
