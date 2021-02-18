module RSpec
  module Matchers
    RSpec.describe "expect(actual).to be_within(delta).of(expected)" do
      it_behaves_like "an RSpec value matcher", :valid_value => 5, :invalid_value => -5 do
        let(:matcher) { be_within(2).of(4.0) }
      end

      it "passes when actual == expected" do
        expect(5.0).to be_within(0.5).of(5.0)
      end

      it "passes when actual < (expected + delta)" do
        expect(5.49).to be_within(0.5).of(5.0)
      end

      it "passes when actual > (expected - delta)" do
        expect(4.51).to be_within(0.5).of(5.0)
      end

      it "passes when actual == (expected - delta)" do
        expect(4.5).to be_within(0.5).of(5.0)
      end

      it "passes when actual == (expected + delta)" do
        expect(5.5).to be_within(0.5).of(5.0)
      end

      it "passes with integer arguments that are near each other" do
        expect(1.0001).to be_within(5).percent_of(1)
      end

      it "passes with negative arguments" do
        expect(-1.0001).to be_within(5).percent_of(-1)
      end

      it "fails when actual < (expected - delta)" do
        expect {
          expect(4.49).to be_within(0.5).of(5.0)
        }.to fail_with("expected 4.49 to be within 0.5 of 5.0")
      end

      it "fails when actual > (expected + delta)" do
        expect {
          expect(5.51).to be_within(0.5).of(5.0)
        }.to fail_with("expected 5.51 to be within 0.5 of 5.0")
      end

      it "works with Time" do
        expect(Time.now).to be_within(0.1).of(Time.now)
      end

      it "provides a description" do
        matcher = be_within(0.5).of(5.0)
        matcher.matches?(5.1)
        expect(matcher.description).to eq "be within 0.5 of 5.0"
      end

      it "formats expected within description" do
        klass = Class.new { def inspect; "5"; end }
        matcher = be_within(0.5).of(klass.new)
        expect(matcher.description).to eq "be within 0.5 of 5"
      end

      it "raises an error if no expected value is given" do
        expect {
          expect(5.1).to be_within(0.5)
        }.to raise_error(ArgumentError, /must set an expected value using #of/)
      end

      it "fails if the actual is not numeric" do
        expect {
          expect(nil).to be_within(0.1).of(0)
        }.to fail_with("expected nil to be within 0.1 of 0, but it could not be treated as a numeric value")
      end
    end

    RSpec.describe "expect(actual).to be_within(delta).percent_of(expected)" do
      it "passes when actual is within the given percent variance" do
        expect(9.0).to be_within(10).percent_of(10.0)
        expect(10.0).to be_within(10).percent_of(10.0)
        expect(11.0).to be_within(10).percent_of(10.0)
      end

      it "fails when actual is outside the given percent variance" do
        expect {
          expect(8.9).to be_within(10).percent_of(10.0)
        }.to fail_with("expected 8.9 to be within 10% of 10.0")

        expect {
          expect(11.1).to be_within(10).percent_of(10.0)
        }.to fail_with("expected 11.1 to be within 10% of 10.0")
      end

      it "provides a description" do
        matcher = be_within(0.5).percent_of(5.0)
        matcher.matches?(5.1)
        expect(matcher.description).to eq "be within 0.5% of 5.0"
      end

      it "works with custom measure objects" do
        weight_class = Struct.new(:val) do
          include Comparable
          def <=>(other); val <=> other.val; end
          def -(other); self.class.new(val - other.val); end
          def abs; self.class.new(val.abs); end
          def *(numeric); self.class.new(val * numeric); end
          def /(numeric); self.class.new(val / numeric); end
        end

        expect(weight_class.new(99)).to be_within(2).percent_of(weight_class.new(100))
        expect {
          expect(weight_class.new(90)).to be_within(2).percent_of(weight_class.new(100))
        }.to fail_with(/expected #<struct.*val=90> to be within 2% of #<struct.*val=100>/)
      end
    end

    RSpec.describe "expect(actual).not_to be_within(delta).of(expected)" do
      it "passes when actual < (expected - delta)" do
        expect(4.49).not_to be_within(0.5).of(5.0)
      end

      it "passes when actual > (expected + delta)" do
        expect(5.51).not_to be_within(0.5).of(5.0)
      end

      it "fails when actual == expected" do
        expect {
          expect(5.0).not_to be_within(0.5).of(5.0)
        }.to fail_with("expected 5.0 not to be within 0.5 of 5.0")
      end

      it "fails when actual < (expected + delta)" do
        expect {
          expect(5.49).not_to be_within(0.5).of(5.0)
        }.to fail_with("expected 5.49 not to be within 0.5 of 5.0")
      end

      it "fails when actual > (expected - delta)" do
        expect {
          expect(4.51).not_to be_within(0.5).of(5.0)
        }.to fail_with("expected 4.51 not to be within 0.5 of 5.0")
      end

      it "fails when actual == (expected - delta)" do
        expect {
          expect(4.5).not_to be_within(0.5).of(5.0)
        }.to fail_with("expected 4.5 not to be within 0.5 of 5.0")
      end

      it "fails when actual == (expected + delta)" do
        expect {
          expect(5.5).not_to be_within(0.5).of(5.0)
        }.to fail_with("expected 5.5 not to be within 0.5 of 5.0")
      end

      it "passes if the actual is not numeric" do
        expect(nil).not_to be_within(0.1).of(0)
      end
    end
  end
end
