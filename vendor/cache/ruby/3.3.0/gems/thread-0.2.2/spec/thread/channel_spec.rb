require 'thread/channel'

describe Thread::Channel do
	it 'receives in the proper order' do
		ch = Thread.channel
		ch.send 'lol'
		ch.send 'wut'

		expect(ch.receive).to eq('lol')
		expect(ch.receive).to eq('wut')
	end

	it 'receives with constraints properly' do
		ch = Thread.channel
		ch.send 'lol'
		ch.send 'wut'

		expect(ch.receive { |v| v == 'wut' }).to eq('wut')
		expect(ch.receive).to eq('lol')
	end

	it 'receives nil when using non blocking mode and the channel is empty' do
		ch = Thread.channel

		expect(ch.receive!).to be_nil
	end

	it 'guards sending properly' do
		ch = Thread.channel { |v| v.is_a? Integer }

		expect {
			ch.send 23
		}.to_not raise_error

		expect {
			ch.send 'lol'
		}.to raise_error
	end
end
