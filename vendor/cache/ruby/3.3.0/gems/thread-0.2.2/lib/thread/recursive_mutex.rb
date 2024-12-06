#--
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                   Version 2, December 2004
#
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'thread'

# A recursive mutex lets you lock in various threads recursively, allowing
# you to do multiple locks one inside another.
#
# You really shouldn't use this, but in some cases it makes your life easier.
class RecursiveMutex < Mutex
	def initialize
		@threads_lock = Mutex.new
		@threads = Hash.new { |h, k| h[k] = 0 }

		super
	end

	# Lock the mutex.
	def lock
		super if @threads_lock.synchronize{ (@threads[Thread.current] += 1) == 1 }
	end

	# Unlock the mutex.
	def unlock
		if @threads_lock.synchronize{ (@threads[Thread.current] -= 1) == 0 }
			@threads.delete(Thread.current)

			super
		end
	end
end
