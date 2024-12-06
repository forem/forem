RSpec.describe Flipper::FeatureCheckContext do
  let(:feature_name) { :new_profiles }
  let(:values) { Flipper::GateValues.new({}) }
  let(:thing) { Flipper::Actor.new('5') }
  let(:options) do
    {
      feature_name: feature_name,
      values: values,
      thing: thing,
    }
  end

  it 'initializes just fine' do
    instance = described_class.new(options)
    expect(instance.feature_name).to eq(feature_name)
    expect(instance.values).to eq(values)
    expect(instance.thing).to eq(thing)
  end

  it 'requires feature_name' do
    options.delete(:feature_name)
    expect do
      described_class.new(options)
    end.to raise_error(KeyError)
  end

  it 'requires values' do
    options.delete(:values)
    expect do
      described_class.new(options)
    end.to raise_error(KeyError)
  end

  it 'requires thing' do
    options.delete(:thing)
    expect do
      described_class.new(options)
    end.to raise_error(KeyError)
  end

  it 'knows actors_value' do
    args = options.merge(values: Flipper::GateValues.new(actors: Set['User;1']))
    expect(described_class.new(args).actors_value).to eq(Set['User;1'])
  end

  it 'knows groups_value' do
    args = options.merge(values: Flipper::GateValues.new(groups: Set['admins']))
    expect(described_class.new(args).groups_value).to eq(Set['admins'])
  end

  it 'knows boolean_value' do
    instance = described_class.new(options.merge(values: Flipper::GateValues.new(boolean: true)))
    expect(instance.boolean_value).to eq(true)
  end

  it 'knows percentage_of_actors_value' do
    args = options.merge(values: Flipper::GateValues.new(percentage_of_actors: 14))
    expect(described_class.new(args).percentage_of_actors_value).to eq(14)
  end

  it 'knows percentage_of_time_value' do
    args = options.merge(values: Flipper::GateValues.new(percentage_of_time: 41))
    expect(described_class.new(args).percentage_of_time_value).to eq(41)
  end
end
