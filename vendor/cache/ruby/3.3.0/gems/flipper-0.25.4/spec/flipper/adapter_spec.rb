RSpec.describe Flipper::Adapter do
  let(:source_flipper) { build_flipper }
  let(:destination_flipper) { build_flipper }
  let(:default_config) do
    {
      boolean: nil,
      groups: Set.new,
      actors: Set.new,
      percentage_of_actors: nil,
      percentage_of_time: nil,
    }
  end

  describe '.default_config' do
    it 'returns default config' do
      adapter_class = Class.new do
        include Flipper::Adapter
      end
      expect(adapter_class.default_config).to eq(default_config)
    end
  end

  describe '#default_config' do
    it 'returns default config' do
      adapter_class = Class.new do
        include Flipper::Adapter
      end
      expect(adapter_class.new.default_config).to eq(default_config)
    end
  end

  describe '#import' do
    it 'returns nothing' do
      result = destination_flipper.import(source_flipper)
      expect(result).to be(nil)
    end

    it 'can import from one adapter to another' do
      source_flipper.enable(:search)
      destination_flipper.import(source_flipper)
      expect(destination_flipper[:search].boolean_value).to eq(true)
      expect(destination_flipper.features.map(&:key).sort).to eq(%w(search))
    end

    it 'can import features that have been added but their state is off' do
      source_flipper.add(:search)
      destination_flipper.import(source_flipper)
      expect(destination_flipper.features.map(&:key)).to eq(["search"])
    end

    it 'can import multiple features' do
      source_flipper.enable(:yep)
      source_flipper.enable_group(:preview_features, :developers)
      source_flipper.enable_group(:preview_features, :marketers)
      source_flipper.enable_group(:preview_features, :company)
      source_flipper.enable_group(:preview_features, :early_access)
      source_flipper.enable_actor(:preview_features, Flipper::Actor.new('1'))
      source_flipper.enable_actor(:preview_features, Flipper::Actor.new('2'))
      source_flipper.enable_actor(:preview_features, Flipper::Actor.new('3'))
      source_flipper.enable_percentage_of_actors(:issues_next, 25)
      source_flipper.enable_percentage_of_time(:verbose_logging, 5)

      destination_flipper.import(source_flipper)

      feature = destination_flipper[:yep]
      expect(feature.boolean_value).to be(true)
      expect(feature.groups_value).to eq(Set[])
      expect(feature.actors_value).to eq(Set[])
      expect(feature.percentage_of_actors_value).to be(0)
      expect(feature.percentage_of_time_value).to be(0)

      feature = destination_flipper[:preview_features]
      expect(feature.boolean_value).to be(false)
      expect(feature.actors_value).to eq(Set['1', '2', '3'])
      expected_groups = Set['developers', 'marketers', 'company', 'early_access']
      expect(feature.groups_value).to eq(expected_groups)
      expect(feature.percentage_of_actors_value).to be(0)
      expect(feature.percentage_of_time_value).to be(0)

      feature = destination_flipper[:issues_next]
      expect(feature.boolean_value).to eq(false)
      expect(feature.actors_value).to eq(Set.new)
      expect(feature.groups_value).to eq(Set.new)
      expect(feature.percentage_of_actors_value).to be(25)
      expect(feature.percentage_of_time_value).to be(0)

      feature = destination_flipper[:verbose_logging]
      expect(feature.boolean_value).to eq(false)
      expect(feature.actors_value).to eq(Set.new)
      expect(feature.groups_value).to eq(Set.new)
      expect(feature.percentage_of_actors_value).to be(0)
      expect(feature.percentage_of_time_value).to be(5)
    end

    it 'wipes existing enablements for adapter' do
      destination_flipper.enable(:stats)
      destination_flipper.enable_percentage_of_time(:verbose_logging, 5)
      source_flipper.enable_percentage_of_time(:stats, 5)
      source_flipper.enable_percentage_of_actors(:verbose_logging, 25)

      destination_flipper.import(source_flipper)

      feature = destination_flipper[:stats]
      expect(feature.boolean_value).to be(false)
      expect(feature.percentage_of_time_value).to be(5)

      feature = destination_flipper[:verbose_logging]
      expect(feature.percentage_of_time_value).to be(0)
      expect(feature.percentage_of_actors_value).to be(25)
    end

    it 'wipes existing features for adapter' do
      destination_flipper.add(:stats)
      destination_flipper.import(source_flipper)
      expect(destination_flipper.features.map(&:key)).to eq([])
    end
  end
end
