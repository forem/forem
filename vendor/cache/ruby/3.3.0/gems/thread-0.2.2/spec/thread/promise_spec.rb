require 'thread/promise'

describe Thread::Promise do
	it 'delivers a value properly' do
		p = Thread.promise

		Thread.new {
			sleep 0.02

			p << 42
		}

		expect(p.value).to eq(42)
	end

	it 'properly checks if anything has been delivered' do
		p = Thread.promise

		Thread.new {
			sleep 0.02

			p << 42
		}

		expect(p.delivered?).to be(false)
		sleep 0.03
		expect(p.delivered?).to be(true)
	end

	it 'does not block when a timeout is passed' do
		p = Thread.promise

		expect(p.value(0)).to be(nil)
	end
end
