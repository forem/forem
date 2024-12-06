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

# A pipe lets you execute various tasks on a set of data in parallel,
# each datum inserted in the pipe is passed along through queues to the various
# functions composing the pipe, the final result is inserted in the final queue.
class Thread::Pipe
	# A task encapsulates a part of the pipe.
	class Task
		attr_accessor :input, :output

		# Create a Task which will call the passed function and get input
		# from the optional parameter and put output in the optional parameter.
		def initialize(func, input = Queue.new, output = Queue.new)
			@input    = input
			@output   = output
			@handling = false

			@thread = Thread.new {
				while true
					value = @input.deq

					@handling = true
					begin
						value = func.call(value)
						@output.enq value
					rescue Exception; end
					@handling = false
				end
			}
		end

		# Check if the task has nothing to do.
		def empty?
			!@handling && @input.empty? && @output.empty?
		end

		# Stop the task.
		def kill
			@thread.raise
		end
	end

	# Create a pipe using the optionally passed objects as input and
	# output queue.
	#
	# The objects must respond to #enq and #deq, and block on #deq.
	def initialize(input = Queue.new, output = Queue.new)
		@tasks = []

		@input  = input
		@output = output

		ObjectSpace.define_finalizer self, self.class.finalizer(@tasks)
	end

	# @private
	def self.finalizer(tasks)
		proc {
			tasks.each(&:kill)
		}
	end

	# Add a task to the pipe, it must respond to #call and #arity,
	# and #arity must return 1.
	def |(func)
		if func.arity != 1
			raise ArgumentError, 'wrong arity'
		end

		Task.new(func, (@tasks.empty? ? @input : Queue.new), @output).tap {|t|
			@tasks.last.output = t.input unless @tasks.empty?
			@tasks << t
		}

		self
	end

	# Check if the pipe is empty.
	def empty?
		@input.empty? && @output.empty? && @tasks.all?(&:empty?)
	end

	# Insert data in the pipe.
	def enq(data)
		return if @tasks.empty?

		@input.enq data

		self
	end

	alias push enq
	alias <<   enq

	# Get an element from the output queue.
	def deq(non_block = false)
		@output.deq(non_block)
	end

	alias pop deq
	alias ~   deq
end

class Thread
	# Helper to create a pipe.
	def self.|(func)
		Pipe.new | func
	end
end
