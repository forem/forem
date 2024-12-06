require 'flipper/identifier'

RSpec.describe Flipper::Identifier do
  describe '#flipper_id' do
    class User < Struct.new(:id)
      include Flipper::Identifier
    end

    it 'uses class name and id' do
      expect(User.new(5).flipper_id).to eq('User;5')
    end
  end
end
