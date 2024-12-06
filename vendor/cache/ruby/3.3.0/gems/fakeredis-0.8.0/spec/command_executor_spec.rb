require 'spec_helper'

RSpec.describe FakeRedis::CommandExecutor do
  
  let(:redis) { Redis.new }

  context '#write' do
    it 'does not modify its argument' do
      command = [:get, 'key']
      redis.write(command)
      expect(command).to eql([:get, 'key'])
    end
  end

end