require "active_support"
require "active_support/test_case"

RSpec.describe "redirect_to" do
  include RSpec::Rails::Matchers::RedirectTo

  let(:response) { ActionDispatch::TestResponse.new }

  context "with should" do
    context "when assert_redirected_to passes" do
      def assert_redirected_to(*); end

      it "passes" do
        expect do
          expect(response).to redirect_to("destination")
        end.to_not raise_exception
      end
    end

    context "when assert_redirected_to fails" do
      def assert_redirected_to(*)
        raise ActiveSupport::TestCase::Assertion.new("this message")
      end

      it "uses failure message from assert_redirected_to" do
        expect do
          expect(response).to redirect_to("destination")
        end.to raise_exception("this message")
      end
    end

    context "when fails due to some other exception" do
      def assert_redirected_to(*)
        raise "oops"
      end

      it "raises that exception" do
        expect do
          expect(response).to redirect_to("destination")
        end.to raise_exception("oops")
      end
    end
  end

  context "with should_not" do
    context "when assert_redirected_to fails" do
      def assert_redirected_to(*)
        raise ActiveSupport::TestCase::Assertion.new("this message")
      end

      it "passes" do
        expect do
          expect(response).not_to redirect_to("destination")
        end.to_not raise_exception
      end
    end

    context "when assert_redirected_to passes" do
      def assert_redirected_to(*); end

      it "fails with custom failure message" do
        expect do
          expect(response).not_to redirect_to("destination")
        end.to raise_exception(/expected not to redirect to \"destination\", but did/)
      end
    end

    context "when fails due to some other exception" do
      def assert_redirected_to(*)
        raise "oops"
      end

      it "raises that exception" do
        expect do
          expect(response).not_to redirect_to("destination")
        end.to raise_exception("oops")
      end
    end
  end
end
