#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'thread'

# A pool is a container of a limited amount of threads to which you can add
# tasks to run.
#
# This is usually more performant and less memory intensive than creating a
# new thread for every task.
class Thread::Pool
	# A task incapsulates a block being ran by the pool and the arguments to pass
	# to it.
	class Task
		Timeout = Class.new(Exception)
		Asked   = Class.new(Exception)

		attr_reader :pool, :timeout, :exception, :thread, :started_at, :result

		# Create a task in the given pool which will pass the arguments to the
		# block.
		def initialize(pool, *args, &block)
			@pool      = pool
			@arguments = args
			@block     = block

			@running    = false
			@finished   = false
			@timedout   = false
			@terminated = false
		end

		def running?
			@running
		end

		def finished?
			@finished
		end

		def timeout?
			@timedout
		end

		def terminated?
			@terminated
		end

		# Execute the task.
		def execute
			return if terminated? || running? || finished?

			@thread     = Thread.current
			@running    = true
			@started_at = Time.now

			pool.__send__ :wake_up_timeout

			begin
				@result = @block.call(*@arguments)
			rescue Exception => reason
				if reason.is_a? Timeout
					@timedout = true
				elsif reason.is_a? Asked
					return
				else
					@exception = reason
					raise @exception if Thread::Pool.abort_on_exception
				end
			end

			@running  = false
			@finished = true
			@thread   = nil
		end

		# Raise an exception in the thread used by the task.
		def raise(exception)
			@thread.raise(exception) if @thread
		end

		# Terminate the exception with an optionally given exception.
		def terminate!(exception = Asked)
			return if terminated? || finished? || timeout?

			@terminated = true

			return unless running?

			self.raise exception
		end

		# Force the task to timeout.
		def timeout!
			terminate! Timeout
		end

		# Timeout the task after the given time.
		def timeout_after(time)
			@timeout = time

			pool.__send__ :timeout_for, self, time

			self
		end
	end

	attr_reader :min, :max, :spawned, :waiting

	# Create the pool with minimum and maximum threads.
	#
	# The pool will start with the minimum amount of threads created and will
	# spawn new threads until the max is reached in case of need.
	#
	# A default block can be passed, which will be used to {#process} the passed
	# data.
	def initialize(min, max = nil, &block)
		@min   = min
		@max   = max || min
		@block = block

		@cond  = ConditionVariable.new
		@mutex = Mutex.new

		@done       = ConditionVariable.new
		@done_mutex = Mutex.new

		@todo     = []
		@workers  = []
		@timeouts = {}

		@spawned       = 0
		@waiting       = 0
		@shutdown      = false
		@trim_requests = 0
		@auto_trim     = false
		@idle_trim     = nil

		@mutex.synchronize {
			min.times {
				spawn_thread
			}
		}
	end

	# Check if the pool has been shut down.
	def shutdown?
		!!@shutdown
	end

	# Check if auto trimming is enabled.
	def auto_trim?
		@auto_trim
	end

	# Enable auto trimming, unneeded threads will be deleted until the minimum
	# is reached.
	def auto_trim!
		@auto_trim = true

		self
	end

	# Disable auto trimming.
	def no_auto_trim!
		@auto_trim = false

		self
	end

	# Check if idle trimming is enabled.
	def idle_trim?
		!@idle_trim.nil?
	end

	# Enable idle trimming. Unneeded threads will be deleted after the given number of seconds of inactivity.
	# The minimum number of threads is respeced.
	def idle_trim!(timeout)
		@idle_trim = timeout

		self
	end

	# Turn of idle trimming.
	def no_idle_trim!
		@idle_trim = nil

		self
	end

	# Resize the pool with the passed arguments.
	def resize(min, max = nil)
		@min = min
		@max = max || min

		trim!
	end

	# Get the amount of tasks that still have to be run.
	def backlog
		@mutex.synchronize {
			@todo.length
		}
	end

	# Are all tasks consumed?
	def done?
		@mutex.synchronize {
			_done?
		}
	end

	# Wait until all tasks are consumed. The caller will be blocked until then.
	def wait(what = :idle)
		case what
		when :done
			until done?
				@done_mutex.synchronize {
					break if _done?

					@done.wait @done_mutex
				}
			end

		when :idle
			until idle?
				@done_mutex.synchronize {
					break if _idle?

					@done.wait @done_mutex
				}
			end
		end

		self
	end

	# Check if there are idle workers.
	def idle?
		@mutex.synchronize {
			_idle?
		}
	end

	# Add a task to the pool which will execute the block with the given
	# argument.
	#
	# If no block is passed the default block will be used if present, an
	# ArgumentError will be raised otherwise.
	def process(*args, &block)
		unless block || @block
			raise ArgumentError, 'you must pass a block'
		end

		task = Task.new(self, *args, &(block || @block))

		@mutex.synchronize {
			raise 'unable to add work while shutting down' if shutdown?

			@todo << task

			if @waiting == 0 && @spawned < @max
				spawn_thread
			end

			@cond.signal
		}

		task
	end

	alias << process

	# Trim the unused threads, if forced threads will be trimmed even if there
	# are tasks waiting.
	def trim(force = false)
		@mutex.synchronize {
			if (force || @waiting > 0) && @spawned - @trim_requests > @min
				@trim_requests += 1
				@cond.signal
			end
		}

		self
	end

	# Force #{trim}.
	def trim!
		trim true
	end

	# Shut down the pool instantly without finishing to execute tasks.
	def shutdown!
		@mutex.synchronize {
			@shutdown = :now
			@cond.broadcast
		}

		wake_up_timeout

		self
	end

	# Shut down the pool, it will block until all tasks have finished running.
	def shutdown
		@mutex.synchronize {
			@shutdown = :nicely
			@cond.broadcast
		}

		until @workers.empty?
			if worker = @workers.first
				worker.join
			end
		end

		if @timeout
			@shutdown = :now

			wake_up_timeout

			@timeout.join
		end
	end

	# Shutdown the pool after a given amount of time.
	def shutdown_after(timeout)
		Thread.new {
			sleep timeout

			shutdown
		}
	end

	class << self
		# If true, tasks will allow raised exceptions to pass through.
		#
		# Similar to Thread.abort_on_exception
		attr_accessor :abort_on_exception
	end

private
	def timeout_for(task, timeout)
		unless @timeout
			spawn_timeout_thread
		end

		@mutex.synchronize {
			@timeouts[task] = timeout

			wake_up_timeout
		}
	end

	def wake_up_timeout
		if defined? @pipes
			@pipes.last.write_nonblock 'x' rescue nil
		end
	end

	def spawn_thread
		@spawned += 1

		thread = Thread.new {
			loop do
				task = @mutex.synchronize {
					if @todo.empty?
						while @todo.empty?
							if @trim_requests > 0
								@trim_requests -= 1

								break
							end

							break if shutdown?

							@waiting += 1

							done!

							if @idle_trim and @spawned > @min
								check_time = Time.now + @idle_trim
								@cond.wait @mutex, @idle_trim
								@trim_requests += 1 if Time.now >= check_time && @spawned - @trim_requests > @min
							else
								@cond.wait @mutex
							end

							@waiting -= 1
						end

						break if @todo.empty? && shutdown?
					end

					@todo.shift
				} or break

				task.execute

				break if @shutdown == :now

				trim if auto_trim? && @spawned > @min
			end

			@mutex.synchronize {
				@spawned -= 1
				@workers.delete thread
			}
		}

		@workers << thread

		thread
	end

	def spawn_timeout_thread
		@pipes   = IO.pipe
		@timeout = Thread.new {
			loop do
				now     = Time.now
				timeout = @timeouts.map {|task, time|
					next unless task.started_at

					now - task.started_at + task.timeout
				}.compact.min unless @timeouts.empty?

				readable, = IO.select([@pipes.first], nil, nil, timeout)

				break if @shutdown == :now

				if readable && !readable.empty?
					readable.first.read_nonblock 1024
				end

				now = Time.now
				@timeouts.each {|task, time|
					next if !task.started_at || task.terminated? || task.finished?

					if now > task.started_at + task.timeout
						task.timeout!
					end
				}

				@timeouts.reject! { |task, _| task.terminated? || task.finished? }

				break if @shutdown == :now
			end
		}
	end

	def _done?
		@todo.empty? and @waiting == @spawned
	end

	def _idle?
		@todo.length < @waiting
	end

	def done!
		@done_mutex.synchronize {
			@done.broadcast if _done? or _idle?
		}
	end
end

class Thread
	# Helper to create a pool.
	def self.pool(*args, &block)
		Thread::Pool.new(*args, &block)
	end
end
