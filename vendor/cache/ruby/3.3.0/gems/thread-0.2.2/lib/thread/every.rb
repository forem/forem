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

# An every runs the given block every given seconds, you can then get the
# value, check if the value is old and you can check how many seconds
# until the next run.
class Thread::Every
	Cancel  = Class.new(Exception)
	Restart = Class.new(Exception)

	# Create an every with the given seconds and block.
	def initialize(every, &block)
		raise ArgumentError, 'no block given' unless block

		@every  = every
		@old    = true
		@mutex  = Mutex.new
		@thread = Thread.new {
			loop do
				begin
					value = block.call

					@mutex.synchronize {
						@at        = Time.now
						@value     = value
						@old       = false
						@exception = nil
					}
				rescue Restart
					next
				rescue Exception => e
					@mutex.synchronize {
						@at        = Time.now
						@exception = e
					}

					break if e.is_a? Cancel
				end

				cond.broadcast if cond?

				begin
					sleep @every
				rescue Restart
					next
				rescue Cancel => e
					@mutex.synchronize {
						@at        = Time.now
						@exception = e
					}

					break
				end
			end
		}

		ObjectSpace.define_finalizer self, self.class.finalizer(@thread)
	end

	# @private
	def self.finalizer(thread)
		proc {
			thread.raise Cancel.new
		}
	end

	# Change the number of seconds between each call.
	def every(seconds)
		@every = seconds

		restart
	end

	# Cancel the every, {#value} will yield a Cancel exception.
	def cancel
		@mutex.synchronize {
			@thread.raise Cancel.new('every cancelled')
		}

		self
	end

	# Check if the every has been cancelled.
	def cancelled?
		@mutex.synchronize {
			@exception.is_a? Cancel
		}
	end

	# Checks when the every was cancelled.
	def cancelled_at
		if cancelled?
			@mutex.synchronize {
				@at
			}
		end
	end

	# Restart the every.
	def restart
		@mutex.synchronize {
			@thread.raise Restart.new
		}

		self
	end

	# Check if the every is running.
	def running?
		!cancelled?
	end

	# Check if the every is old, after the first #value call it becomes old,
	# until another run of the block is gone)
	def old?
		@mutex.synchronize {
			@old
		}
	end

	# Gets the Time when the block was called.
	def called_at
		@mutex.synchronize {
			@at
		}
	end

	# Gets how many seconds are missing before another call.
	def next_in
		return if cancelled?

		@mutex.synchronize {
			@every - (Time.now - @at)
		}
	end

	# Gets the current every value.
	def value(timeout = nil)
		@mutex.synchronize {
			if @old
				cond.wait(@mutex, *timeout)
			end

			@old = true

			if @exception
				raise @exception
			else
				@value
			end
		}
	end

	alias ~ value

	# Gets the current every value, without blocking and waiting for the next
	# call.
	def value!
		@mutex.synchronize {
			@old = true

			@value unless @exception
		}
	end

private
	def cond?
		instance_variable_defined? :@cond
	end

	def cond
		@cond ||= ConditionVariable.new
	end
end

class Thread
	# Helper to create an every
	def self.every(every, &block)
		Thread::Every.new(every, &block)
	end
end

module Kernel
	# Helper to create an every
	def every(every, &block)
		Thread::Every.new(every, &block)
	end
end
