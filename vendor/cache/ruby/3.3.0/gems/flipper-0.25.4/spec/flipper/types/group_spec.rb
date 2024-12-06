require 'flipper/types/group'

RSpec.describe Flipper::Types::Group do
  let(:fake_context) { double('FeatureCheckContext') }

  subject do
    Flipper.register(:admins, &:admin?)
  end

  describe '.wrap' do
    context 'with group instance' do
      it 'returns group instance' do
        expect(described_class.wrap(subject)).to eq(subject)
      end
    end

    context 'with Symbol group name' do
      it 'returns group instance' do
        expect(described_class.wrap(subject.name)).to eq(subject)
      end
    end

    context 'with String group name' do
      it 'returns group instance' do
        expect(described_class.wrap(subject.name.to_s)).to eq(subject)
      end
    end
  end

  it 'initializes with name' do
    group = described_class.new(:admins)
    expect(group).to be_instance_of(described_class)
  end

  describe '#name' do
    it 'returns name' do
      expect(subject.name).to eq(:admins)
    end
  end

  describe '#match?' do
    let(:admin_actor) { double('Actor', admin?: true) }
    let(:non_admin_actor) { double('Actor', admin?: false) }

    it 'returns true if block matches' do
      expect(subject.match?(admin_actor, fake_context)).to eq(true)
    end

    it 'returns false if block does not match' do
      expect(subject.match?(non_admin_actor, fake_context)).to eq(false)
    end

    it 'returns true for truthy block results' do
      group = described_class.new(:examples) do |actor|
        actor.email =~ /@example\.com/
      end
      expect(group.match?(double('Actor', email: 'foo@example.com'), fake_context)).to be_truthy
    end

    it 'returns false for falsey block results' do
      group = described_class.new(:examples) do |_actor|
        nil
      end
      expect(group.match?(double('Actor'), fake_context)).to be_falsey
    end

    it 'returns true for truthy shortand block results' do
      actor = Class.new do
        def admin?
          true
        end
      end.new

      group = described_class.new(:admin, &:admin?)
      expect(group.match?(actor, fake_context)).to be_truthy
    end

    it 'returns false for falsy shortand block results' do
      actor = Class.new do
        def admin?
          false
        end
      end.new

      group = described_class.new(:admin, &:admin?)
      expect(group.match?(actor, fake_context)).to be_falsey
    end

    it 'can yield without context as block argument' do
      context = Flipper::FeatureCheckContext.new(
        feature_name: :my_feature,
        values: Flipper::GateValues.new({}),
        thing: Flipper::Types::Actor.new(Flipper::Actor.new(1))
      )
      group = Flipper.register(:group_with_context) { |actor| actor }
      yielded_actor = group.match?(admin_actor, context)
      expect(yielded_actor).to be(admin_actor)
    end

    it 'can yield with context as block argument' do
      context = Flipper::FeatureCheckContext.new(
        feature_name: :my_feature,
        values: Flipper::GateValues.new({}),
        thing: Flipper::Types::Actor.new(Flipper::Actor.new(1))
      )
      group = Flipper.register(:group_with_context) { |actor, context| [actor, context] }
      yielded_actor, yielded_context = group.match?(admin_actor, context)
      expect(yielded_actor).to be(admin_actor)
      expect(yielded_context).to be(context)
    end
  end
end
