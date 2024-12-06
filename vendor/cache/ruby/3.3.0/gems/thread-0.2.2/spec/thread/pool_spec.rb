require 'thread/pool'

describe Thread::Pool do
	it 'creates a new pool with the given amount of threads' do
		pool = Thread.pool(4)

		expect(pool.spawned).to eq(4)

		pool.shutdown
	end

	it 'creates a new pool with the given amount of threads without spawning more than min' do
		pool = Thread.pool(4, 8)

		expect(pool.spawned).to eq(4)

		pool.shutdown
	end

	it 'properly reports the backlog length' do
		pool = Thread.pool(2)

		pool.process { sleep 0.5 }
		pool.process { sleep 0.5 }
		pool.process { sleep 0.5 }

		sleep 0.25

		expect(pool.backlog).to eq(1)

		pool.shutdown
	end

	it 'properly reports the pool is done' do
		pool = Thread.pool(2)

		pool.process { sleep 0.25 }
		pool.process { sleep 0.25 }
		pool.process { sleep 0.25 }

		expect(pool.done?).to be(false)

		sleep 0.75

		expect(pool.done?).to be(true)

		pool.shutdown
	end

	it 'properly reports the pool is idle' do
		pool = Thread.pool(2)

		pool.process { sleep 0.25 }
		pool.process { sleep 0.5 }

		expect(pool.idle?).to be(false)

		sleep 0.30

		expect(pool.idle?).to be(true)

		pool.shutdown
	end

	it 'properly shutdowns the pool' do
		result = []
		pool   = Thread.pool(4)

		pool.process { sleep 0.1; result << 1 }
		pool.process { sleep 0.2; result << 2 }
		pool.process { sleep 0.3; result << 3 }
		pool.process { sleep 0.4; result << 4 }

		pool.shutdown

		expect(result).to eq([1, 2, 3, 4])
	end
end
