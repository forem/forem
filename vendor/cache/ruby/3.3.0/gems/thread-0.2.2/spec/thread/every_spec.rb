require 'thread/every'

describe Thread::Every do
	it 'delivers a value properly' do
		e = Thread.every(5) { sleep 0.02; 42 }

		expect(e.value).to eq(42)
	end
end
