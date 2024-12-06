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

# A promise is an object that lets you wait for a value to be delivered to it.
class Thread::Promise
	# Create a promise.
	def initialize
		@mutex = Mutex.new
	end

	# Check if a value has been delivered.
	def delivered?
		@mutex.synchronize {
			instance_variable_defined? :@value
		}
	end

	alias realized? delivered?

	# Deliver a value.
	def deliver(value)
		return self if delivered?

		@mutex.synchronize {
			@value = value

			cond.broadcast if cond?
		}

		self
	end

	alias << deliver

	# Get the value that's been delivered, if none has been delivered yet the call
	# will block until one is delivered.
	#
	# An optional timeout can be passed which will return nil if nothing has been
	# delivered.
	def value(timeout = nil)
		return @value if delivered?

		@mutex.synchronize {
			cond.wait(@mutex, *timeout)
		}

		return @value if delivered?
	end

	alias ~ value

private
	def cond?
		instance_variable_defined? :@cond
	end

	def cond
		@cond ||= ConditionVariable.new
	end
end

class Thread
	# Helper method to create a promise.
	def self.promise
		Thread::Promise.new
	end
end

module Kernel
	# Helper method to create a promise.
	def promise
		Thread::Promise.new
	end
end
