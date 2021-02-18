module RSpec
  RSpec.describe Matchers do

    let(:sample_matchers) do
      [:be,
       :be_instance_of,
       :be_kind_of]
    end

    context "once required", :slow do
      include MinitestIntegration

      it "includes itself in Minitest::Test, and sets up our exceptions to be counted as assertion failures" do
        with_minitest_loaded do
          minitest_case = MiniTest::Test.allocate
          expect(minitest_case).to respond_to(*sample_matchers)

          expect(RSpec::Expectations::ExpectationNotMetError).to be ::Minitest::Assertion
        end
      end

    end

  end
end
