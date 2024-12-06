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
require 'weakref'

# A future is an object that incapsulates a block which is called in a
# different thread, upon retrieval the caller gets blocked until the block has
# finished running, and its result is returned and cached.
class Thread::Future
	Cancel = Class.new(Exception)

	# Create a future with the passed block and optionally using the passed pool.
	def initialize(pool = nil, &block)
		raise ArgumentError, 'no block given' unless block

		@mutex = Mutex.new

		task = proc {
			begin
				deliver block.call
			rescue Exception => e
				@exception = e

				deliver nil
			end
		}

		@thread = pool ? pool.process(&task) : Thread.new(&task)

		ObjectSpace.define_finalizer self, self.class.finalizer(WeakRef.new(@thread))
	end

	# @private
	def self.finalizer(thread)
		proc {
			if thread.weakref_alive?
				if thread.is_a? Thread
					thread.raise Cancel
				else
					thread.terminate! Cancel
				end
			end
		}
	end

	# Check if an exception has been raised.
	def exception?
		@mutex.synchronize {
			instance_variable_defined? :@exception
		}
	end

	# Return the raised exception.
	def exception
		@mutex.synchronize {
			@exception
		}
	end

	# Check if the future has been called.
	def delivered?
		@mutex.synchronize {
			instance_variable_defined? :@value
		}
	end

	alias realized? delivered?

	# Cancel the future, {#value} will yield a Cancel exception
	def cancel
		return self if delivered?

		@mutex.synchronize {
			if @thread.is_a? Thread
				@thread.raise Cancel
			else
				@thread.terminate! Cancel
			end

			@exception = Cancel.new
		}

		self
	end

	# Check if the future has been cancelled
	def cancelled?
		@mutex.synchronize {
			@exception.is_a? Cancel
		}
	end

	# Get the value of the future, if it's not finished running this call will block.
	#
	# In case the block raises an exception, it will be raised, the exception is cached
	# and will be raised every time you access the value.
	#
	# An optional timeout can be passed which will return nil if nothing has been
	# delivered.
	def value(timeout = nil)
		raise @exception if exception?

		return @value if delivered?

		@mutex.synchronize {
			cond.wait(@mutex, *timeout)
		}

		if exception?
			raise @exception
		elsif delivered?
			return @value
		end
	end

	alias ~ value

	# Do the same as {#value}, but return nil in case of exception.
	def value!(timeout = nil)
		begin
			value(timeout)
		rescue Exception
			nil
		end
	end

	alias ! value!

private
	def cond?
		instance_variable_defined? :@cond
	end

	def cond
		@cond ||= ConditionVariable.new
	end

	def deliver (value)
		return if delivered?

		@mutex.synchronize {
			@value = value

			cond.broadcast if cond?
		}

		self
	end
end

class Thread
	# Helper to create a future
	def self.future(pool = nil, &block)
		Thread::Future.new(pool, &block)
	end
end

module Kernel
	# Helper to create a future.
	def future(pool = nil, &block)
		Thread::Future.new(pool, &block)
	end
end

class Thread::Pool
	def future(&block)
		Thread.future self, &block
	end
end
