require 'rspec/support/reentrant_mutex'
require 'thread_order'

# There are no assertions specifically
# They are pass if they don't deadlock
RSpec.describe RSpec::Support::ReentrantMutex do
  let!(:mutex) { described_class.new }
  let!(:order) { ThreadOrder.new }
  after { order.apocalypse! }

  it 'can repeatedly synchronize within the same thread' do
    mutex.synchronize { mutex.synchronize { } }
  end

  it 'locks other threads out while in the synchronize block' do
    order.declare(:before) { mutex.synchronize { } }
    order.declare(:within) { mutex.synchronize { } }
    order.declare(:after)  { mutex.synchronize { } }

    order.pass_to :before, :resume_on => :exit
    mutex.synchronize { order.pass_to :within, :resume_on => :sleep }
    order.pass_to :after, :resume_on => :exit
  end

  it 'resumes the next thread once all its synchronize blocks have completed' do
    order.declare(:thread) { mutex.synchronize { } }
    mutex.synchronize { order.pass_to :thread, :resume_on => :sleep }
    order.join_all
  end
end
