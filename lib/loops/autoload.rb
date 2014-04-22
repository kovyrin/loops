module Loops
  # @private
  def self.__p(*path) File.join(Loops::LIB_ROOT, 'loops', *path) end

  autoload :Base,           __p('base')
  autoload :CLI,            __p('cli')
  autoload :Command,        __p('command')
  autoload :Commands,       __p('command')
  autoload :Daemonize,      __p('daemonize')
  autoload :Engine,         __p('engine')
  autoload :Errors,         __p('errors')
  autoload :Logger,         __p('logger')
  autoload :ProcessManager, __p('process_manager')
  autoload :Queue,          __p('queue')
  autoload :BunnyQueue,     __p('bunny_queue')
  autoload :Worker,         __p('worker')
  autoload :WorkerPool,     __p('worker_pool')

  include Errors
end
