require "spec_helper"

module RSpec
  module Support
    RSpec.describe "matcher definitions" do
      RSpec::Matchers.define :fake_matcher do |expected|
        match { |actual| expected == actual }
        description { :fake_matcher }
      end

      RSpec::Matchers.define :matcher_with_no_description do
        match { true }
        undef description
      end

      describe ".rspec_description_for_object" do
        it "returns the object for a non matcher object" do
          o = Object.new
          expect(RSpec::Support.rspec_description_for_object(o)).to be o
        end

        it "returns the object's description for a matcher object that has a description" do
          expect(RSpec::Support.rspec_description_for_object(fake_matcher(nil))).to eq :fake_matcher
        end

        it "returns the object for a matcher that does not have a description" do
          matcher = matcher_with_no_description

          expect(matcher_with_no_description).not_to respond_to(:description)
          expect(RSpec::Support.is_a_matcher?(matcher_with_no_description)).to eq true

          expect(RSpec::Support.rspec_description_for_object(matcher)).to be matcher
        end
      end
    end
  end
end
