require 'thread/delay'

describe Thread::Delay do
	it 'delivers a value properly' do
		d = Thread.delay {
			42
		}

		expect(d.value).to eq(42)
	end
end
