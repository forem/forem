require 'flipper/adapters/read_only'

RSpec.describe Flipper::Adapters::ReadOnly do
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(subject) }
  let(:feature) { flipper[:stats] }

  let(:boolean_gate) { feature.gate(:boolean) }
  let(:group_gate)   { feature.gate(:group) }
  let(:actor_gate)   { feature.gate(:actor) }
  let(:actors_gate)  { feature.gate(:percentage_of_actors) }
  let(:time_gate)    { feature.gate(:percentage_of_time) }

  subject { described_class.new(adapter) }

  before do
    Flipper.register(:admins) do |actor|
      actor.respond_to?(:admin?) && actor.admin?
    end

    Flipper.register(:early_access) do |actor|
      actor.respond_to?(:early_access?) && actor.early_access?
    end
  end

  after do
    Flipper.unregister_groups
  end

  it 'has name that is a symbol' do
    expect(subject.name).not_to be_nil
    expect(subject.name).to be_instance_of(Symbol)
  end

  it 'has included the flipper adapter module' do
    expect(subject.class.ancestors).to include(Flipper::Adapter)
  end

  it 'returns correct default values for the gates if none are enabled' do
    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can get feature' do
    actor22 = Flipper::Actor.new('22')
    adapter.enable(feature, boolean_gate, flipper.boolean)
    adapter.enable(feature, group_gate, flipper.group(:admins))
    adapter.enable(feature, actor_gate, flipper.actor(actor22))
    adapter.enable(feature, actors_gate, flipper.actors(25))
    adapter.enable(feature, time_gate, flipper.time(45))

    expect(subject.get(feature)).to eq(boolean: 'true',
                                       groups: Set['admins'],
                                       actors: Set['22'],
                                       percentage_of_actors: '25',
                                       percentage_of_time: '45')
  end

  it 'can get features' do
    expect(subject.features).to eq(Set.new)
    adapter.add(feature)
    expect(subject.features).to eq(Set['stats'])
  end

  it 'raises error on add' do
    expect { subject.add(feature) }.to raise_error(Flipper::Adapters::ReadOnly::WriteAttempted)
  end

  it 'raises error on remove' do
    expect { subject.remove(feature) }.to raise_error(Flipper::Adapters::ReadOnly::WriteAttempted)
  end

  it 'raises on clear' do
    expect { subject.clear(feature) }.to raise_error(Flipper::Adapters::ReadOnly::WriteAttempted)
  end

  it 'raises error on enable' do
    expect { subject.enable(feature, boolean_gate, flipper.boolean) }
      .to raise_error(Flipper::Adapters::ReadOnly::WriteAttempted)
  end

  it 'raises error on disable' do
    expect { subject.disable(feature, boolean_gate, flipper.boolean) }
      .to raise_error(Flipper::Adapters::ReadOnly::WriteAttempted)
  end
end
