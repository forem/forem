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

# A channel lets you send and receive various messages in a thread-safe way.
#
# It also allows for guards upon sending and retrieval, to ensure the passed
# messages are safe to be consumed.
class Thread::Channel
	# Create a channel with optional initial messages and optional channel guard.
	def initialize(messages = [], &block)
		@messages = []
		@mutex    = Mutex.new
		@check    = block

		messages.each {|o|
			send o
		}
	end

	# Send a message to the channel.
	#
	# If there's a guard, the value is passed to it, if the guard returns a falsy value
	# an ArgumentError exception is raised and the message is not sent.
	def send(what)
		if @check && !@check.call(what)
			raise ArgumentError, 'guard mismatch'
		end

		@mutex.synchronize {
			@messages << what

			cond.broadcast if cond?
		}

		self
	end

	# Receive a message, if there are none the call blocks until there's one.
	#
	# If a block is passed, it's used as guard to match to a message.
	def receive(&block)
		message = nil
		found   = false

		if block
			until found
				@mutex.synchronize {
					if index = @messages.find_index(&block)
						message = @messages.delete_at(index)
						found   = true
					else
						cond.wait @mutex
					end
				}
			end
		else
			until found
				@mutex.synchronize {
					if @messages.empty?
						cond.wait @mutex
					end

					unless @messages.empty?
						message = @messages.shift
						found   = true
					end
				}
			end
		end

		message
	end

	# Receive a message, if there are none the call returns nil.
	#
	# If a block is passed, it's used as guard to match to a message.
	def receive!(&block)
		if block
			@messages.delete_at(@messages.find_index(&block))
		else
			@messages.shift
		end
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
	# Helper to create a channel.
	def self.channel(*args, &block)
		Thread::Channel.new(*args, &block)
	end
end
