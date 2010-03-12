require 'yaml'
require 'erb'

module Loops
  ROOT   = File.expand_path(File.dirname(__FILE__))
  BINARY = File.expand_path(File.join(ROOT, '../bin/loops'))
end

require File.join(Loops::ROOT, 'loops/autoload')
