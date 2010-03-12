module Loops
  # @private
  def self.__p(*path) File.join(Loops::ROOT, 'loops', *path) end

  autoload :Base,           __p('base')
  autoload :CLI,            __p('cli')
  autoload :Daemonize,      __p('daemonize')
  autoload :Engine,         __p('engine')
  autoload :Logger,         __p('logger')
  autoload :ProcessManager, __p('process_manager')
  autoload :Queue,          __p('queue')
  autoload :Worker,         __p('worker')
  autoload :WorkerPool,     __p('worker_pool')
end
