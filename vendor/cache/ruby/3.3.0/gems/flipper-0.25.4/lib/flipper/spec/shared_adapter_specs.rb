# Requires the following methods:
# * subject - The instance of the adapter
RSpec.shared_examples_for 'a flipper adapter' do
  let(:flipper) { Flipper.new(subject) }
  let(:feature) { flipper[:stats] }

  let(:boolean_gate) { feature.gate(:boolean) }
  let(:group_gate)   { feature.gate(:group) }
  let(:actor_gate)   { feature.gate(:actor) }
  let(:actors_gate)  { feature.gate(:percentage_of_actors) }
  let(:time_gate) { feature.gate(:percentage_of_time) }

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

  it 'can enable, disable and get value for boolean gate' do
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)

    result = subject.get(feature)
    expect(result[:boolean]).to eq('true')

    expect(subject.disable(feature, boolean_gate, flipper.boolean(false))).to eq(true)

    result = subject.get(feature)
    expect(result[:boolean]).to eq(nil)
  end

  it 'fully disables all enabled things when boolean gate disabled' do
    actor22 = Flipper::Actor.new('22')
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, flipper.actors(25))).to eq(true)
    expect(subject.enable(feature, time_gate, flipper.time(45))).to eq(true)

    expect(subject.disable(feature, boolean_gate, flipper.boolean(false))).to eq(true)

    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can enable, disable and get value for group gate' do
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:early_access))).to eq(true)

    result = subject.get(feature)
    expect(result[:groups]).to eq(Set['admins', 'early_access'])

    expect(subject.disable(feature, group_gate, flipper.group(:early_access))).to eq(true)
    result = subject.get(feature)
    expect(result[:groups]).to eq(Set['admins'])

    expect(subject.disable(feature, group_gate, flipper.group(:admins))).to eq(true)
    result = subject.get(feature)
    expect(result[:groups]).to eq(Set.new)
  end

  it 'can enable, disable and get value for actor gate' do
    actor22 = Flipper::Actor.new('22')
    actor_asdf = Flipper::Actor.new('asdf')

    expect(subject.enable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor_asdf))).to eq(true)

    result = subject.get(feature)
    expect(result[:actors]).to eq(Set['22', 'asdf'])

    expect(subject.disable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    result = subject.get(feature)
    expect(result[:actors]).to eq(Set['asdf'])

    expect(subject.disable(feature, actor_gate, flipper.actor(actor_asdf))).to eq(true)
    result = subject.get(feature)
    expect(result[:actors]).to eq(Set.new)
  end

  it 'can enable, disable and get value for percentage of actors gate' do
    expect(subject.enable(feature, actors_gate, flipper.actors(15))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_actors]).to eq('15')

    expect(subject.disable(feature, actors_gate, flipper.actors(0))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_actors]).to eq('0')
  end

  it 'can enable percentage of actors gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.enable(feature, actors_gate, flipper.actors(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_actors]).to eq(percentage.to_s)
    end
  end

  it 'can disable percentage of actors gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.disable(feature, actors_gate, flipper.actors(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_actors]).to eq(percentage.to_s)
    end
  end

  it 'can enable, disable and get value for percentage of time gate' do
    expect(subject.enable(feature, time_gate, flipper.time(10))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('10')

    expect(subject.disable(feature, time_gate, flipper.time(0))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('0')
  end

  it 'can enable percentage of time gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.enable(feature, time_gate, flipper.time(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_time]).to eq(percentage.to_s)
    end
  end

  it 'can disable percentage of time gate many times and consistently return values' do
    (1..100).each do |percentage|
      expect(subject.disable(feature, time_gate, flipper.time(percentage))).to eq(true)
      result = subject.get(feature)
      expect(result[:percentage_of_time]).to eq(percentage.to_s)
    end
  end

  it 'converts boolean value to a string' do
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    result = subject.get(feature)
    expect(result[:boolean]).to eq('true')
  end

  it 'converts the actor value to a string' do
    expect(subject.enable(feature, actor_gate, flipper.actor(Flipper::Actor.new(22)))).to eq(true)
    result = subject.get(feature)
    expect(result[:actors]).to eq(Set['22'])
  end

  it 'converts group value to a string' do
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    result = subject.get(feature)
    expect(result[:groups]).to eq(Set['admins'])
  end

  it 'converts percentage of time integer value to a string' do
    expect(subject.enable(feature, time_gate, flipper.time(10))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_time]).to eq('10')
  end

  it 'converts percentage of actors integer value to a string' do
    expect(subject.enable(feature, actors_gate, flipper.actors(10))).to eq(true)
    result = subject.get(feature)
    expect(result[:percentage_of_actors]).to eq('10')
  end

  it 'can add, remove and list known features' do
    expect(subject.features).to eq(Set.new)

    expect(subject.add(flipper[:stats])).to eq(true)
    expect(subject.features).to eq(Set['stats'])

    expect(subject.add(flipper[:search])).to eq(true)
    expect(subject.features).to eq(Set['stats', 'search'])

    expect(subject.remove(flipper[:stats])).to eq(true)
    expect(subject.features).to eq(Set['search'])

    expect(subject.remove(flipper[:search])).to eq(true)
    expect(subject.features).to eq(Set.new)
  end

  it 'clears all the gate values for the feature on remove' do
    actor22 = Flipper::Actor.new('22')
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, flipper.actors(25))).to eq(true)
    expect(subject.enable(feature, time_gate, flipper.time(45))).to eq(true)

    expect(subject.remove(feature)).to eq(true)

    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'can clear all the gate values for a feature' do
    actor22 = Flipper::Actor.new('22')
    subject.add(feature)
    expect(subject.features).to include(feature.key)

    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor22))).to eq(true)
    expect(subject.enable(feature, actors_gate, flipper.actors(25))).to eq(true)
    expect(subject.enable(feature, time_gate, flipper.time(45))).to eq(true)

    expect(subject.clear(feature)).to eq(true)
    expect(subject.features).to include(feature.key)
    expect(subject.get(feature)).to eq(subject.default_config)
  end

  it 'does not complain clearing a feature that does not exist in adapter' do
    expect(subject.clear(flipper[:stats])).to eq(true)
  end

  it 'can get multiple features' do
    expect(subject.add(flipper[:stats])).to eq(true)
    expect(subject.enable(flipper[:stats], boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.add(flipper[:search])).to eq(true)

    result = subject.get_multi([flipper[:stats], flipper[:search], flipper[:other]])
    expect(result).to be_instance_of(Hash)

    stats = result["stats"]
    search = result["search"]
    other = result["other"]
    expect(stats).to eq(subject.default_config.merge(boolean: 'true'))
    expect(search).to eq(subject.default_config)
    expect(other).to eq(subject.default_config)
  end

  it 'can get all features' do
    expect(subject.add(flipper[:stats])).to eq(true)
    expect(subject.enable(flipper[:stats], boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.add(flipper[:search])).to eq(true)

    result = subject.get_all
    expect(result).to be_instance_of(Hash)

    stats = result["stats"]
    search = result["search"]
    expect(stats).to eq(subject.default_config.merge(boolean: 'true'))
    expect(search).to eq(subject.default_config)
  end

  it 'includes explicitly disabled features when getting all features' do
    flipper.enable(:stats)
    flipper.enable(:search)
    flipper.disable(:search)

    result = subject.get_all
    expect(result.keys.sort).to eq(%w(search stats))
  end

  it 'can double enable an actor without error' do
    actor = Flipper::Actor.new('Flipper::Actor;22')
    expect(subject.enable(feature, actor_gate, flipper.actor(actor))).to eq(true)
    expect(subject.enable(feature, actor_gate, flipper.actor(actor))).to eq(true)
    expect(subject.get(feature).fetch(:actors)).to eq(Set['Flipper::Actor;22'])
  end

  it 'can double enable a group without error' do
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.enable(feature, group_gate, flipper.group(:admins))).to eq(true)
    expect(subject.get(feature).fetch(:groups)).to eq(Set['admins'])
  end

  it 'can double enable percentage without error' do
    expect(subject.enable(feature, actors_gate, flipper.actors(25))).to eq(true)
    expect(subject.enable(feature, actors_gate, flipper.actors(25))).to eq(true)
  end

  it 'can double enable without error' do
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
    expect(subject.enable(feature, boolean_gate, flipper.boolean)).to eq(true)
  end

  it 'can get_all features when there are none' do
    expect(subject.features).to eq(Set.new)
    expect(subject.get_all).to eq({})
  end

  it 'clears other gate values on enable' do
    actor = Flipper::Actor.new('Flipper::Actor;22')
    subject.enable(feature, actors_gate, flipper.actors(25))
    subject.enable(feature, time_gate, flipper.time(25))
    subject.enable(feature, group_gate, flipper.group(:admins))
    subject.enable(feature, actor_gate, flipper.actor(actor))
    subject.enable(feature, boolean_gate, flipper.boolean(true))
    expect(subject.get(feature)).to eq(subject.default_config.merge(boolean: "true"))
  end
end
