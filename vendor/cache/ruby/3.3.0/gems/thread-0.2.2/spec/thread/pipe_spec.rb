require 'thread/pipe'

describe Thread::Pipe do
	it 'handles passing properly' do
		p = Thread |-> d { d * 2 } |-> d { d * 4 }

		p << 2
		p << 4

		expect(p.deq).to eq(16)
		expect(p.deq).to eq(32)
	end

	it 'empty works properly' do
		p = Thread |-> d { sleep 0.02; d * 2 } |-> d { d * 4 }

		expect(p.empty?).to be(true)
		p.enq 42
		expect(p.empty?).to be(false)
		p.deq
		expect(p.empty?).to be(true)
	end
end
