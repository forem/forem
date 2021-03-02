module RSpec
  module Matchers
    RSpec.describe "eql" do
      it_behaves_like "an RSpec value matcher", :valid_value => 1, :invalid_value => 2 do
        let(:matcher) { eql(1) }
      end

      it "is diffable" do
        expect(eql(1)).to be_diffable
      end

      it "matches when actual.eql?(expected)" do
        expect(1).to eql(1)
      end

      it "does not match when !actual.eql?(expected)" do
        expect(1).not_to eql(2)
      end

      it "describes itself" do
        matcher = eql(1)
        matcher.matches?(1)
        expect(matcher.description).to eq "eql 1"
      end

      it "provides message, expected and actual on #failure_message" do
        matcher = eql("1")
        matcher.matches?(1)
        expect(matcher.failure_message).to eq "\nexpected: \"1\"\n     got: 1\n\n(compared using eql?)\n"
      end

      it "provides message, expected and actual on #negative_failure_message" do
        matcher = eql(1)
        matcher.matches?(1)
        expect(matcher.failure_message_when_negated).to eq "\nexpected: value != 1\n     got: 1\n\n(compared using eql?)\n"
      end
    end
  end
end
