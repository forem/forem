require 'flipper/feature'

RSpec.describe Flipper do
  let(:adapter)     { Flipper::Adapters::Memory.new }
  let(:flipper)     { described_class.new(adapter) }
  let(:feature)     { flipper[:search] }
  let(:admin_group) { flipper.group(:admins) }
  let(:dev_group)   { flipper.group(:devs) }

  let(:admin_thing) do
    double 'Non Flipper Thing', flipper_id: 1,  admin?: true, dev?: false
  end
  let(:dev_thing) do
    double 'Non Flipper Thing', flipper_id: 10, admin?: false, dev?: true
  end

  let(:admin_truthy_thing) do
    double 'Non Flipper Thing', flipper_id: 1,  admin?: 'true-ish', dev?: false
  end
  let(:admin_falsey_thing) do
    double 'Non Flipper Thing', flipper_id: 1,  admin?: nil, dev?: false
  end

  let(:pitt)        { Flipper::Actor.new(1) }
  let(:clooney)     { Flipper::Actor.new(10) }

  let(:five_percent_of_actors) { flipper.actors(5) }
  let(:five_percent_of_time) { flipper.time(5) }

  before do
    described_class.register(:admins, &:admin?)
    described_class.register(:devs, &:dev?)
  end

  describe '#enable' do
    context 'with no arguments' do
      before do
        @result = feature.enable
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'enables feature for all' do
        expect(feature.enabled?).to eq(true)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with a group' do
      before do
        @result = feature.enable(admin_group)
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'enables feature for non flipper thing in group' do
        expect(feature.enabled?(admin_thing)).to eq(true)
      end

      it 'does not enable feature for non flipper thing in other group' do
        expect(feature.enabled?(dev_thing)).to eq(false)
      end

      it 'enables feature for flipper actor in group' do
        expect(feature.enabled?(flipper.actor(admin_thing))).to eq(true)
      end

      it 'does not enable for flipper actor not in group' do
        expect(feature.enabled?(flipper.actor(dev_thing))).to eq(false)
      end

      it 'does not enable feature for all' do
        expect(feature.enabled?).to eq(false)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with an actor' do
      before do
        @result = feature.enable(pitt)
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'enables feature for actor' do
        expect(feature.enabled?(pitt)).to eq(true)
      end

      it 'does not enable feature for other actors' do
        expect(feature.enabled?(clooney)).to eq(false)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with a percentage of actors' do
      before do
        @result = feature.enable(five_percent_of_actors)
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'enables feature for actor within percentage' do
        enabled = (1..100).select do |i|
          thing = Flipper::Actor.new(i)
          feature.enabled?(thing)
        end.size

        expect(enabled).to be_within(2).of(5)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with a float percentage of actors' do
      before do
        @result = feature.enable_percentage_of_actors 5.1
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'enables feature for actor within percentage' do
        enabled = (1..100).select do |i|
          thing = Flipper::Actor.new(i)
          feature.enabled?(thing)
        end.size

        expect(enabled).to be_within(2).of(5)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with a percentage of time' do
      before do
        @gate = feature.gate(:percentage_of_time)
        @result = feature.enable(five_percent_of_time)
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'enables feature for time within percentage' do
        allow(@gate).to receive_messages(rand: 0.04)
        expect(feature.enabled?).to eq(true)
      end

      it 'does not enable feature for time not within percentage' do
        allow(@gate).to receive_messages(rand: 0.10)
        expect(feature.enabled?).to eq(false)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with argument that has no gate' do
      it 'raises error' do
        thing = Object.new
        expect do
          feature.enable(thing)
        end.to raise_error(Flipper::GateNotFound, "Could not find gate for #{thing.inspect}")
      end
    end
  end

  describe '#disable' do
    context 'with no arguments' do
      before do
        # ensures that time gate is stubbed with result that would be true for pitt
        @gate = feature.gate(:percentage_of_time)
        allow(@gate).to receive_messages(rand: 0.04)

        feature.enable admin_group
        feature.enable pitt
        feature.enable five_percent_of_actors
        feature.enable five_percent_of_time
        @result = feature.disable
      end

      it 'returns true' do
        expect(@result).to be(true)
      end

      it 'disables feature' do
        expect(feature.enabled?).to eq(false)
      end

      it 'disables for individual actor' do
        expect(feature.enabled?(pitt)).to eq(false)
      end

      it 'disables actor in group' do
        expect(feature.enabled?(admin_thing)).to eq(false)
      end

      it 'disables actor in percentage of actors' do
        enabled = (1..100).select do |i|
          thing = Flipper::Actor.new(i)
          feature.enabled?(thing)
        end.size

        expect(enabled).to be(0)
      end

      it 'disables percentage of time' do
        expect(feature.enabled?(pitt)).to eq(false)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with a group' do
      before do
        feature.enable dev_group
        feature.enable admin_group
        @result = feature.disable(admin_group)
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'disables the feature for non flipper thing in the group' do
        expect(feature.enabled?(admin_thing)).to eq(false)
      end

      it 'does not disable feature for non flipper thing in other groups' do
        expect(feature.enabled?(dev_thing)).to eq(true)
      end

      it 'disables feature for flipper actor in group' do
        expect(feature.enabled?(flipper.actor(admin_thing))).to eq(false)
      end

      it 'does not disable feature for flipper actor in other groups' do
        expect(feature.enabled?(flipper.actor(dev_thing))).to eq(true)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with an actor' do
      before do
        feature.enable pitt
        feature.enable clooney
        @result = feature.disable(pitt)
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'disables feature for actor' do
        expect(feature.enabled?(pitt)).to eq(false)
      end

      it 'does not disable feature for other actors' do
        expect(feature.enabled?(clooney)).to eq(true)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with a percentage of actors' do
      before do
        @result = feature.disable(flipper.actors(0))
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'disables feature' do
        enabled = (1..100).select do |i|
          thing = Flipper::Actor.new(i)
          feature.enabled?(thing)
        end.size

        expect(enabled).to be(0)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with a percentage of time' do
      before do
        @gate = feature.gate(:percentage_of_time)
        @result = feature.disable(flipper.time(0))
      end

      it 'returns true' do
        expect(@result).to eq(true)
      end

      it 'disables feature for time within percentage' do
        allow(@gate).to receive_messages(rand: 0.04)
        expect(feature.enabled?).to eq(false)
      end

      it 'disables feature for time not within percentage' do
        allow(@gate).to receive_messages(rand: 0.10)
        expect(feature.enabled?).to eq(false)
      end

      it 'adds feature to set of features' do
        expect(flipper.features.map(&:name)).to include(:search)
      end
    end

    context 'with argument that has no gate' do
      it 'raises error' do
        thing = Object.new
        expect do
          feature.disable(thing)
        end.to raise_error(Flipper::GateNotFound, "Could not find gate for #{thing.inspect}")
      end
    end
  end

  describe '#enabled?' do
    context 'with no arguments' do
      it 'defaults to false' do
        expect(feature.enabled?).to eq(false)
      end
    end

    context 'with no arguments, but boolean enabled' do
      before do
        feature.enable
      end

      it 'returns true' do
        expect(feature.enabled?).to eq(true)
      end
    end

    context 'for actor in enabled group' do
      before do
        feature.enable admin_group
      end

      it 'returns true' do
        expect(feature.enabled?(flipper.actor(admin_thing))).to eq(true)
        expect(feature.enabled?(admin_thing)).to eq(true)
      end

      it 'returns true for truthy block values' do
        expect(feature.enabled?(flipper.actor(admin_truthy_thing))).to eq(true)
      end
    end

    context 'for actor in disabled group' do
      it 'returns false' do
        expect(feature.enabled?(flipper.actor(dev_thing))).to eq(false)
        expect(feature.enabled?(dev_thing)).to eq(false)
      end

      it 'returns false for falsey block values' do
        expect(feature.enabled?(flipper.actor(admin_falsey_thing))).to eq(false)
      end
    end

    context 'for enabled actor' do
      before do
        feature.enable pitt
      end

      it 'returns true' do
        expect(feature.enabled?(pitt)).to eq(true)
      end
    end

    context 'for not enabled actor' do
      it 'returns false' do
        expect(feature.enabled?(clooney)).to eq(false)
      end

      it 'returns true if boolean enabled' do
        feature.enable
        expect(feature.enabled?(clooney)).to eq(true)
      end
    end

    context 'for enabled percentage of time' do
      before do
        # ensure percentage of time returns percentage that makes five percent
        # of time true
        @gate = feature.gate(:percentage_of_time)
        allow(@gate).to receive_messages(rand: 0.04)

        feature.enable five_percent_of_time
      end

      it 'returns true' do
        expect(feature.enabled?).to eq(true)
        expect(feature.enabled?(nil)).to eq(true)
        expect(feature.enabled?(pitt)).to eq(true)
        expect(feature.enabled?(admin_thing)).to eq(true)
      end
    end

    context 'for enabled float percentage of time' do
      before do
        # ensure percentage of time returns percentage that makes 4.1 percent
        # of time true
        @gate = feature.gate(:percentage_of_time)
        allow(@gate).to receive_messages(rand: 0.04)

        feature.enable_percentage_of_time 4.1
      end

      it 'returns true' do
        expect(feature.enabled?).to eq(true)
        expect(feature.enabled?(nil)).to eq(true)
        expect(feature.enabled?(pitt)).to eq(true)
        expect(feature.enabled?(admin_thing)).to eq(true)
      end
    end

    context 'for NOT enabled integer percentage of time' do
      before do
        # ensure percentage of time returns percentage that makes enabled? false
        @gate = feature.gate(:percentage_of_time)
        allow(@gate).to receive_messages(rand: 0.10)

        feature.enable five_percent_of_time
      end

      it 'returns false' do
        expect(feature.enabled?).to eq(false)
        expect(feature.enabled?(nil)).to eq(false)
        expect(feature.enabled?(pitt)).to eq(false)
        expect(feature.enabled?(admin_thing)).to eq(false)
      end

      it 'returns true if boolean enabled' do
        feature.enable
        expect(feature.enabled?).to eq(true)
        expect(feature.enabled?(nil)).to eq(true)
        expect(feature.enabled?(pitt)).to eq(true)
        expect(feature.enabled?(admin_thing)).to eq(true)
      end
    end

    context 'for NOT enabled float percentage of time' do
      before do
        # ensure percentage of time returns percentage that makes enabled? false
        @gate = feature.gate(:percentage_of_time)
        allow(@gate).to receive_messages(rand: 0.10)

        feature.enable_percentage_of_time 9.9
      end

      it 'returns false' do
        expect(feature.enabled?).to eq(false)
        expect(feature.enabled?(nil)).to eq(false)
        expect(feature.enabled?(pitt)).to eq(false)
        expect(feature.enabled?(admin_thing)).to eq(false)
      end

      it 'returns true if boolean enabled' do
        feature.enable
        expect(feature.enabled?).to eq(true)
        expect(feature.enabled?(nil)).to eq(true)
        expect(feature.enabled?(pitt)).to eq(true)
        expect(feature.enabled?(admin_thing)).to eq(true)
      end
    end

    context 'for a non flipper thing' do
      before do
        feature.enable admin_group
      end

      it 'returns true if in enabled group' do
        expect(feature.enabled?(admin_thing)).to eq(true)
      end

      it 'returns false if not in enabled group' do
        expect(feature.enabled?(dev_thing)).to eq(false)
      end

      it 'returns true if boolean enabled' do
        feature.enable
        expect(feature.enabled?(admin_thing)).to eq(true)
        expect(feature.enabled?(dev_thing)).to eq(true)
      end
    end
  end

  context 'enabling multiple groups, disabling everything, then enabling one group' do
    before do
      feature.enable(admin_group)
      feature.enable(dev_group)
      feature.disable
      feature.enable(admin_group)
    end

    it 'enables feature for object in enabled group' do
      expect(feature.enabled?(admin_thing)).to eq(true)
    end

    it 'does not enable feature for object in not enabled group' do
      expect(feature.enabled?(dev_thing)).to eq(false)
    end
  end
end
