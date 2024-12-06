RSpec.describe Flipper::Gates::PercentageOfActors do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(percentage_of_actors_value, feature = feature_name, thing = nil)
    Flipper::FeatureCheckContext.new(
      feature_name: feature,
      values: Flipper::GateValues.new(percentage_of_actors: percentage_of_actors_value),
      thing: thing || Flipper::Types::Actor.new(Flipper::Actor.new(1))
    )
  end

  describe '#open?' do
    context 'when compared against two features' do
      let(:percentage) { 0.05 }
      let(:percentage_as_integer) { percentage * 100 }
      let(:number_of_actors) { 10_000 }

      let(:actors) do
        (1..number_of_actors).map { |n| Flipper::Actor.new(n) }
      end

      let(:feature_one_enabled_actors) do
        actors.select { |actor| subject.open? context(percentage_as_integer, :name_one, actor) }
      end

      let(:feature_two_enabled_actors) do
        actors.select { |actor| subject.open? context(percentage_as_integer, :name_two, actor) }
      end

      it 'does not enable both features for same set of actors' do
        expect(feature_one_enabled_actors).not_to eq(feature_two_enabled_actors)
      end

      it 'enables feature for accurate number of actors for each feature' do
        margin_of_error = 0.02 * number_of_actors # 2 percent margin of error
        expected_enabled_size = number_of_actors * percentage

        [
          feature_one_enabled_actors.size,
          feature_two_enabled_actors.size,
        ].each do |actual_enabled_size|
          expect(actual_enabled_size).to be_within(margin_of_error).of(expected_enabled_size)
        end
      end
    end

    context 'for fractional percentage' do
      let(:decimal) { 0.001 }
      let(:percentage) { decimal * 100 }
      let(:number_of_actors) { 10_000 }

      let(:actors) do
        (1..number_of_actors).map { |n| Flipper::Actor.new(n) }
      end

      subject { described_class.new }

      it 'enables feature for accurate number of actors' do
        margin_of_error = 0.02 * number_of_actors
        expected_open_count = number_of_actors * decimal

        open_count = actors.select do |actor|
          context = context(percentage, :feature, actor)
          subject.open?(context)
        end.size

        expect(open_count).to be_within(margin_of_error).of(expected_open_count)
      end
    end
  end
end
