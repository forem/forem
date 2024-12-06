#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'thread/channel'

# A process should only interact with the outside through messages, it still
# uses a thread, but it should make it safer to use than sharing and locks.
class Thread::Process
	def self.all
		@@processes ||= {}
	end

	def self.register(name, process)
		all[name] = process
	end

	def self.unregister(name)
		all.delete(name)
	end

	def self.[](name)
		all[name]
	end

	# Create a new process executing the block.
	def initialize(&block)
		@channel = Thread::Channel.new

		Thread.new {
			instance_eval(&block)

			@channel = nil
		}
	end

	# Send a message to the process.
	def send(what)
		unless @channel
			raise RuntimeError, 'the process has terminated'
		end

		@channel.send(what)

		self
	end

	alias << send

private
	def receive
		@channel.receive
	end

	def receive!
		@channel.receive!
	end
end

class Thread
	# Helper to create a process.
	def self.process(&block)
		Thread::Process.new(&block)
	end
end
