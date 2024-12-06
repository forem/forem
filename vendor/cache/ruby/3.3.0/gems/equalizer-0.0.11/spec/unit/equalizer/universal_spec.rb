# encoding: utf-8

require 'spec_helper'

describe Equalizer, '.new' do
  let(:object) { described_class }
  let(:name)   { 'User'          }
  let(:klass)  { ::Class.new     }

  context 'with no keys' do
    subject { object.new }

    before do
      # specify the class #name method
      allow(klass).to receive(:name).and_return(name)
      klass.send(:include, subject)
    end

    let(:instance) { klass.new }

    it { should be_instance_of(object) }

    it { should be_frozen }

    it 'defines #hash and #inspect methods dynamically' do
      expect(subject.public_instance_methods(false).map(&:to_s).sort)
        .to eql(%w[hash inspect])
    end

    describe '#eql?' do
      context 'when the objects are similar' do
        let(:other) { instance.dup }

        it { expect(instance.eql?(other)).to be(true) }
      end

      context 'when the objects are different' do
        let(:other) { double('other') }

        it { expect(instance.eql?(other)).to be(false) }
      end
    end

    describe '#==' do
      context 'when the objects are similar' do
        let(:other) { instance.dup }

        it { expect(instance == other).to be(true) }
      end

      context 'when the objects are different' do
        let(:other) { double('other') }

        it { expect(instance == other).to be(false) }
      end
    end

    describe '#hash' do
      it 'has the expected arity' do
        expect(klass.instance_method(:hash).arity).to be(0)
      end

      it { expect(instance.hash).to eql([klass].hash) }
    end

    describe '#inspect' do
      it 'has the expected arity' do
        expect(klass.instance_method(:inspect).arity).to be(0)
      end

      it { expect(instance.inspect).to eql('#<User>') }
    end
  end

  context 'with keys' do
    subject { object.new(*keys) }

    let(:keys)       { %i[firstname lastname].freeze  }
    let(:firstname)  { 'John'                         }
    let(:lastname)   { 'Doe'                          }
    let(:instance)   { klass.new(firstname, lastname) }

    let(:klass) do
      ::Class.new do
        attr_reader :firstname, :lastname
        private :firstname, :lastname

        def initialize(firstname, lastname)
          @firstname, @lastname = firstname, lastname
        end
      end
    end

    before do
      # specify the class #inspect method
      allow(klass).to receive_messages(name: nil, inspect: name)
      klass.send(:include, subject)
    end

    it { should be_instance_of(object) }

    it { should be_frozen }

    it 'defines #hash and #inspect methods dynamically' do
      expect(subject.public_instance_methods(false).map(&:to_s).sort)
        .to eql(%w[hash inspect])
    end

    describe '#eql?' do
      context 'when the objects are similar' do
        let(:other) { instance.dup }

        it { expect(instance.eql?(other)).to be(true) }
      end

      context 'when the objects are different' do
        let(:other) { double('other') }

        it { expect(instance.eql?(other)).to be(false) }
      end
    end

    describe '#==' do
      context 'when the objects are similar' do
        let(:other) { instance.dup }

        it { expect(instance == other).to be(true) }
      end

      context 'when the objects are different type' do
        let(:other) { klass.new('Foo', 'Bar') }

        it { expect(instance == other).to be(false) }
      end

      context 'when the objects are from different type' do
        let(:other) { double('other') }

        it { expect(instance == other).to be(false) }
      end
    end

    describe '#hash' do
      it 'returns the expected hash' do
        expect(instance.hash)
          .to eql([firstname, lastname, klass].hash)
      end
    end

    describe '#inspect' do
      it 'returns the expected string' do
        expect(instance.inspect)
          .to eql('#<User firstname="John" lastname="Doe">')
      end
    end
  end
end
