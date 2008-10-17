#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../config/boot'
require File.dirname(__FILE__) + '/../config/environment'

$LOAD_PATH.unshift("vendor/plugins/loops/lib")

LOOPS_ROOT = Rails.root
LOOPS_CONFIG_FILE = LOOPS_ROOT + "/config/loops.yml"

require 'ext/em'
require 'ext/emfork'
require 'loops'

puts "Loading config..."
Loops.load_config(LOOPS_CONFIG_FILE)

puts "Starting workers"
Loops.start_loops!
