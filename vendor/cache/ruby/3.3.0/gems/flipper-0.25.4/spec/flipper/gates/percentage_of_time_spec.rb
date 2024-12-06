RSpec.describe Flipper::Gates::PercentageOfTime do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(percentage_of_time_value, feature = feature_name, thing = nil)
    Flipper::FeatureCheckContext.new(
      feature_name: feature,
      values: Flipper::GateValues.new(percentage_of_time: percentage_of_time_value),
      thing: thing || Flipper::Types::Actor.new(Flipper::Actor.new(1))
    )
  end

  describe '#open?' do
    context 'for fractional percentage' do
      let(:decimal) { 0.001 }
      let(:percentage) { decimal * 100 }
      let(:number_of_invocations) { 10_000 }

      subject { described_class.new }

      it 'enables feature for accurate percentage of time' do
        margin_of_error = 0.02 * number_of_invocations
        expected_open_count = number_of_invocations * decimal

        open_count = (1..number_of_invocations).select do |_actor|
          context = context(percentage, :feature, Flipper::Actor.new("1"))
          subject.open?(context)
        end.size

        expect(open_count).to be_within(margin_of_error).of(expected_open_count)
      end
    end
  end
end
