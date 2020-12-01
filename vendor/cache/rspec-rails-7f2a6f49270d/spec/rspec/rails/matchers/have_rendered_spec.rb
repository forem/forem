%w[have_rendered render_template].each do |template_expectation|
  RSpec.describe template_expectation do
    include RSpec::Rails::Matchers::RenderTemplate
    let(:response) { ActionDispatch::TestResponse.new }

    context "given a hash" do
      def assert_template(*); end
      it "delegates to assert_template" do
        expect(self).to receive(:assert_template).with({this: "hash"}, "this message")
        expect("response").to send(template_expectation, {this: "hash"}, "this message")
      end
    end

    context "given a string" do
      def assert_template(*); end
      it "delegates to assert_template" do
        expect(self).to receive(:assert_template).with("this string", "this message")
        expect("response").to send(template_expectation, "this string", "this message")
      end
    end

    context "given a symbol" do
      def assert_template(*); end
      it "converts to_s and delegates to assert_template" do
        expect(self).to receive(:assert_template).with("template_name", "this message")
        expect("response").to send(template_expectation, :template_name, "this message")
      end
    end

    context "with should" do
      context "when assert_template passes" do
        def assert_template(*); end
        it "passes" do
          expect do
            expect(response).to send(template_expectation, "template_name")
          end.to_not raise_exception
        end
      end

      context "when assert_template fails" do
        it "uses failure message from assert_template" do
          def assert_template(*)
            raise ActiveSupport::TestCase::Assertion.new("this message")
          end
          expect do
            expect(response).to send(template_expectation, "template_name")
          end.to raise_error("this message")
        end
      end

      context "when fails due to some other exception" do
        it "raises that exception" do
          def assert_template(*)
            raise "oops"
          end
          expect do
            expect(response).to send(template_expectation, "template_name")
          end.to raise_exception("oops")
        end
      end
    end

    context "with should_not" do
      context "when assert_template fails" do
        it "passes" do
          def assert_template(*)
            raise ActiveSupport::TestCase::Assertion.new("this message")
          end
          expect do
            expect(response).to_not send(template_expectation, "template_name")
          end.to_not raise_exception
        end
      end

      context "when assert_template passes" do
        it "fails with custom failure message" do
          def assert_template(*); end
          expect do
            expect(response).to_not send(template_expectation, "template_name")
          end.to raise_error(/expected not to render \"template_name\", but did/)
        end
      end

      context "when fails due to some other exception" do
        it "raises that exception" do
          def assert_template(*); raise "oops"; end
          expect do
            expect(response).to_not send(template_expectation, "template_name")
          end.to raise_exception("oops")
        end
      end

      context "when fails with a redirect" do
        let(:response) { ActionDispatch::TestResponse.new(303) }

        def assert_template(*)
          message = "expecting <'template_name'> but rendering with <[]>"
          raise ActiveSupport::TestCase::Assertion.new(message)
        end

        def normalize_argument_to_redirection(_response_redirect_location)
          "http://test.host/widgets/1"
        end

        it "gives informative error message" do
          response = ActionDispatch::TestResponse.new(302)
          response.location = "http://test.host/widgets/1"
          expect do
            expect(response).to send(template_expectation, "template_name")
          end.to raise_exception("expecting <'template_name'> but was a redirect to <http://test.host/widgets/1>")
        end

        context 'with a badly formatted error message' do
          def assert_template(*)
            message = 'expected [] to include "some/path"'
            raise ActiveSupport::TestCase::Assertion.new(message)
          end

          it 'falls back to something informative' do
            expect do
              expect(response).to send(template_expectation, "template_name")
            end.to raise_exception('expected [] to include "some/path" but was a redirect to <http://test.host/widgets/1>')
          end
        end
      end
    end
  end
end
