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

# A delay is an object that incapsulates a block which is called upon
# value retrieval, and its result cached.
class Thread::Delay
	# Create a delay with the passed block.
	def initialize (&block)
		raise ArgumentError, 'no block given' unless block

		@mutex = Mutex.new
		@block = block
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

	# Check if the delay has been called.
	def delivered?
		@mutex.synchronize {
			instance_variable_defined? :@value
		}
	end

	alias realized? delivered?

	# Get the value of the delay, if it's already been executed, return the
	# cached result, otherwise execute the block and return the value.
	#
	# In case the block raises an exception, it will be raised, the exception is
	# cached and will be raised every time you access the value.
	def value
		@mutex.synchronize {
			raise @exception if instance_variable_defined? :@exception

			return @value if instance_variable_defined? :@value

			begin
				@value = @block.call
			rescue Exception => e
				@exception = e

				raise
			end
		}
	end

	alias ~ value

	# Do the same as {#value}, but return nil in case of exception.
	def value!
		begin
			value
		rescue Exception
			nil
		end
	end

	alias ! value!
end

class Thread
	# Helper to create Thread::Delay
	def self.delay (&block)
		Thread::Delay.new(&block)
	end
end

module Kernel
	# Helper to create a Thread::Delay
	def delay (&block)
		Thread::Delay.new(&block)
	end
end
