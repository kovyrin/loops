# Simple background loops framework

`loops` is a small and lightweight framework for Ruby on Rails, Merb and other
ruby frameworks created to support simple background loops in your application
which are usually used to do some background data processing on your servers
(queue workers, batch tasks processors, etc).

*Warning*: If you use some pre-2.0 version of this plugin, read a dedicated
paragraph below.

## What would you use it for?

Originally loops plugin was created to make our own loops code a bit more
organized. We used to have dozens of different modules with methods that were
called with script/runner and then used with `nohup` and other painful
backgrounding techniques. When you have such a number of loops/workers to run
in background it becomes a nightmare to manage them on a regular basis
(restarts, code upgrades, status/health checking, etc).

After a few takes on writing our scripts in a more organized way we were able
to generalize most of the code so now our loops started looking like a classes
with a single mandatory public method called **run**. Everything else
(spawning many workers, managing them, logging, backgrounding, pid-files
management, etc) is handled by the plugin itself.

## But there are dozens of libraries like this! Why do we need yet another one?

The major idea behind this small project was to create a deadly simple and yet
robust framework to be able to run some tasks in background and do not think
about spawning many workers, restarting them when they die, etc. So, if you
need to be able to run either one or many copies of your worker and you do not
want to think about re-spawning your scripts when they die and you do not want
to spend megabytes of RAM on separate copies of Ruby interpreter (when you run
each copy of your loop as a separate process controlled by monit/god/etc),
then you should try this framework -- you're going to like it.

## How to install?

Add the loops gem to your `Gemfile`:

```ruby
gem 'loops'
```

And then run the `bundle` command to install the gem.

## How to use?

Here is a simple loop scaffold for you to start from (put this file to
`app/loops/hello_world_loop.rb`):

```ruby
class HelloWorldLoop < Loops::Base
  config_option :period, :kind_of => Integer, :default => 30

  def run
    with_period_of(period) do # period is in seconds, read from config file
      debug("Hello, debug log!")
      sleep(1) # Do something "useful" here
      debug("Hello, debug log (yes, once again)!")
    end
  end
end
```

When you have your loop ready to use, add the following lines to your (maybe
empty still) `config/loops.yml` file `loops` section:

```yaml
loops:
  hello_world:
    period: 10
```

This is it! To manage your loop, just run one of the following commands:

*   To list all configured loops:

        $ loops list

*   To run all enabled (actually non-disabled) loops in foreground:

        $ loops start

*   To run all enabled non-disabled loops with logging mirrored to console
    (this method does not create any pid files and never releases control of
    the terminal, so it is the perfect way of running loops under the control
    of a supervisor like supervisord/runit/upstart/systemd/docker):

        $ loops monitor

*   To run all enabled loops in background:

        $ loops start -d

*   To run specific loop in background:

        $ loops start hello_world -d

*   To run specific loop in foreground with logging mirrored to console:

        $ loops monitor hello_world

*   To see all possible options:

        $ loops help

## How to run more than one worker?

If you want to have more than one copy of your worker running, that is as easy
as adding one option to your loop configuration:

```yaml
loops:
  hello_world:
    sleep_period: 10
    workers_number: 2
```

This `workers_number` option would tell loops manager to spawn more than one
copy of your loop and run them in parallel. The only thing you'd need to do is
to remember about concurrent work of your loops. For example, if you have some
kind of database table with elements you need to process, you can create a
simple database-based locks system or use any memcache-based locks.

## How to run more than one loop using the same class?

You can run the same loop class with different configuration parameters by
explicitly identifying the loop class to execute:

```yaml
loops:
  hello:
    loop_name: some_module/my_worker
    language: English

  salut:
    loop_name: some_module/my_worker
    language: French
```

Now two independent sets of loops are using the same class
`SomeModule::MyWorkerLoop` customized by the language parameter.

## How to initialize the loop before workers run?

You can run initialization code before starting loop workers by implementing
the initialize_loop class method.  If initialize_loop raises an error, then
the loop is not started and the error is logged.

```ruby
class HelloWorldLoop < Loops::Base
  config_option :dependency_file, :required => true
  config_option :sleep_period, :kind_of => Integer, :default => 5

  def self.initialize_loop(config)
    unless File.exist?(dependency_file)
      raise "Missing required dependency"
    end
  end

  def run
    with_period_of(1) do # period is in seconds
        debug("Hello, debug log!")
        sleep(sleep_period) # Do something "useful" and make it configurable
        debug("Hello, debug log (yes, once again)!")
    end
  end
end
```

## How do I detect if my code is running in a loop?

We provide an api call `Loops.running?` that returns `true` if your code is
running as a part of a loops process. For example, if you want your
Rails.logger to write logs into your Loops logger (when you run it in a loop),
you could do something like the following in your environment files:

```ruby
# Switch logger to loops if we are in a loops process
config.logger = Loops.logger if Loops.running?
```

## I want to keep my loop running on machine reboots. How to do it?

We use monit to keep loop monitors runnings. You could use something like this
in your configs:

```
check process loop-slow_logs with pidfile /your/project/current/tmp/pids/loop-slow_logs.pid
  group loops
  start program "/bin/bash -c 'cd /your/project/current && /usr/bin/bundle exec loops start slow_logs -p /your/project/shared/pids/loop-slow_logs.pid -e loops -d'"
  stop  program "/bin/bash -c 'cd /your/project/current && /usr/bin/bundle exec loops stop -p /your/project/shared/pids/loop-slow_logs.pid'"
```

## ActiveMQ-based workers? What's that?

In some of our worker loops we poll ActiveMQ queue and process its items to
perform some asynchronous operations. So, to make it simpler for us to create
such a workers, we've created really simple loops class extension that wraps
your code with basic queue polling/acknowledging code and as the result, you
can create a loops like this:

```ruby
class MyQueueLoop < Loops::Queue
  def process_message(message)
    debug "Received a message: #{message.body}"
    debug "sleeping..."
    sleep(0.5 + rand(10) / 10.0) # do something "useful" with the message :-)
    debug "done..."
  end
end
```

With configs like this:

```yaml
loops:
  # An example of a STOMP queue-based loop
  my_queue:
    host: 127.0.0.1
    port: 61613
    queue_name: blah
```

This solution scales really well and to make your queue processing faster you
just need to add more workers (by adding `workers_number: N` option).

*Warning*: This type of loops requires you to have the `stomp` gem installed
in your system.

## There is this `workers_engine` option in the config file. What do you use it for?

There are two so called "workers engines" in loops: `fork` and `thread`.
They're used to control the way process manager would spawn new loops workers:
with the `fork` engine we'll load all the loops classes and then fork ruby
interpreter as many times as many workers we need. With the `thread` engine
we'd do Thread.new instead of forking. Thread engine could be useful if you
are sure your loop won't lock ruby interpreter (it does not do native calls,
etc) or if you use some interpreter that does not support forks (like jruby).

The default engine is `fork`.

## What Ruby implementations does it work for?

We've tested and used the plugin on MRI 1.8.6/1.8.7/1.9.3 and on JRuby 1.4.0.
At this point we do not support demonization in JRuby. Obviously because of
JVM limitations you won't be able to use `fork` workers engine in JRuby, but
threaded workers do pretty well.

We have a continuous integration server configured for the project: [<img
src="https://secure.travis-ci.org/kovyrin/loops.png?branch=master" alt="Build
Status" />](http://travis-ci.org/kovyrin/loops)

Recommended version of ruby ro run loops is Ruby Enterprise Edition. This is
because we have a support for their Copy-On-Write friendly garbage collector
that makes your loops much smaller in memory (since they share the most of the
code). Even with one loop process you'd save some memory because your loop
monitor process would share most of the memory with the loop itself. When you
run on RubyEE, you could use `loops stats` command to get detailed loops
memory stats:

```
[root@analyics current]# ./script/loops stats

--------- Loops processes ----------
PID   PPID  VMSize    Private  Name
------------------------------------
9062  1     199.3 MB  32.4 MB  loops monitor: activemq
9234  9062  211.9 MB  37.5 MB  loop worker: activemq
9251  9062  213.3 MB  38.4 MB  loop worker: activemq
9267  9062  211.9 MB  37.1 MB  loop worker: activemq
9268  9062  211.9 MB  38.0 MB  loop worker: activemq
### Processes: 5
### Total private dirty RSS: 183.33 MB
```

## Migrating from pre-2.0 releases

Before version 2.0 has been released, this code was developed as a Rails
plugin only and did not have any versions numbering system in place. So we
call all those old versions a pre-2.0 releases. If you use one of those
releases (if your loops plugin does not have the `VERSION.yml` file in the root
directory), be careful when upgrading because there are a few incompatible
changes we have made in the loops command: `-h`, `-a`, `-s`, `-L` and `-l`
options were deprecated and replaced with a friendlier word commands. Use
`loops help` to get help.

## Who are the authors?

This plugin was created at Scribd for our internal use and then the sources
were opened for other people to use. All the code in this package has
been developed by Oleksiy Kovyrin, Dmytro Shteflyuk and Alexey Verkhovsky
and is released under the MIT license. For more details, see the `LICENSE` file.
