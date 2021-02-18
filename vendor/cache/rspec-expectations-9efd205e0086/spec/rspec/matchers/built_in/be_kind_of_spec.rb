module RSpec
  module Matchers
    [:be_a_kind_of, :be_kind_of].each do |method|
      RSpec.describe "expect(actual).to #{method}(expected)" do
        it_behaves_like "an RSpec value matcher", :valid_value => 5, :invalid_value => "a" do
          let(:matcher) { send(method, Integer) }
        end

        it "passes if actual is instance of expected class" do
          expect("string").to send(method, String)
        end

        it "passes if actual is instance of subclass of expected class" do
          expect(5).to send(method, Numeric)
        end

        it "fails with failure message for should unless actual is kind of expected class" do
          expect {
            expect("foo").to send(method, Array)
          }.to fail_with('expected "foo" to be a kind of Array')
        end

        it "provides a description" do
          matcher = be_a_kind_of(String)
          matcher.matches?("this")
          expect(matcher.description).to eq "be a kind of String"
        end

        context "when the actual object does not respond to #kind_of? method" do
          let(:actual_object) do
            Class.new { undef_method :kind_of? }.new
          end

          it "raises ArgumentError" do
            message = "The be_a_kind_of matcher requires that " \
                      "the actual object responds to #kind_of? method " \
                      "but a `NoMethodError` was encountered instead."

            expect {
              expect(actual_object).to send(method, actual_object.class)
            }.to raise_error ::ArgumentError, message

            expect {
              expect(actual_object).to send(method, Object)
            }.to raise_error ::ArgumentError, message
          end
        end

        context "when the actual object does not respond to #is_a? method" do
          let(:actual_object) do
            Class.new { undef_method :is_a? }.new
          end

          it "provides correct result" do
            expect(actual_object).to send(method, actual_object.class)
            expect(actual_object).to send(method, Object)
          end
        end
      end

      RSpec.describe "expect(actual).not_to #{method}(expected)" do
        it "fails with failure message for should_not if actual is kind of expected class" do
          expect {
            expect("foo").not_to send(method, String)
          }.to fail_with('expected "foo" not to be a kind of String')
        end

        context "when the actual object does not respond to #kind_of? method" do
          let(:actual_object) do
            Class.new { undef_method :kind_of? }.new
          end

          it "raises ArgumentError" do
            message = "The be_a_kind_of matcher requires that " \
                      "the actual object responds to #kind_of? method " \
                      "but a `NoMethodError` was encountered instead."

            expect {
              expect(actual_object).not_to send(method, String)
            }.to raise_error ArgumentError, message
          end
        end

        context "when the actual object does not respond to #is_a? method" do
          let(:actual_object) do
            Class.new { undef_method :is_a? }.new
          end

          it "provides correct result" do
            expect(actual_object).not_to send(method, String)
          end
        end
      end
    end
  end
end
