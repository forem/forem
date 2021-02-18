module RSpec
  module Matchers
    [:be_an_instance_of, :be_instance_of].each do |method|
      RSpec.describe "expect(actual).to #{method}(expected)" do
        it_behaves_like "an RSpec value matcher", :valid_value => "a", :invalid_value => 5 do
          let(:matcher) { send(method, String) }
        end

        it "passes if actual is instance of expected class" do
          expect("a").to send(method, String)
        end

        it "fails if actual is instance of subclass of expected class" do
          expect {
            expect(5).to send(method, Numeric)
          }.to fail_with("expected 5 to be an instance of Numeric")
        end

        it "fails with failure message for should unless actual is instance of expected class" do
          expect {
            expect("foo").to send(method, Array)
          }.to fail_with('expected "foo" to be an instance of Array')
        end

        it "provides a description" do
          matcher = be_an_instance_of(Integer)
          matcher.matches?(Numeric)
          expect(matcher.description).to eq "be an instance of Integer"
        end

        context "when expected provides an expanded inspect, e.g. AR::Base" do
          let(:user_klass) do
            Class.new do
              def self.inspect
                "User(id: integer, name: string)"
              end
            end
          end

          before { stub_const("User", user_klass) }

          it "provides a description including only the class name" do
            matcher = be_an_instance_of(User)
            expect(matcher.description).to eq "be an instance of User"
          end
        end

        context "when the actual object does not respond to #instance_of? method" do
          let(:klass) { Class.new { undef_method :instance_of? } }

          let(:actual_object) { klass.new }

          it "raises ArgumentError" do
            message = "The be_an_instance_of matcher requires that "\
                      "the actual object responds to #instance_of? method " \
                      "but a `NoMethodError` was encountered instead."
            expect {
              expect(actual_object).to send(method, klass)
            }.to raise_error ::ArgumentError, message
          end
        end
      end

      RSpec.describe "expect(actual).not_to #{method}(expected)" do
        it "fails with failure message for should_not if actual is instance of expected class" do
          expect {
            expect("foo").not_to send(method, String)
          }.to fail_with('expected "foo" not to be an instance of String')
        end

        context "when the actual object does not respond to #instance_of? method" do
          let(:klass) { Class.new { undef_method :instance_of? } }

          let(:actual_object) { klass.new }

          it "raises ArgumentError" do
            message = "The be_an_instance_of matcher requires that "\
                      "the actual object responds to #instance_of? method " \
                      "but a `NoMethodError` was encountered instead."
            expect {
              expect(actual_object).not_to send(method, klass)
            }.to raise_error ::ArgumentError, message
          end
        end
      end
    end
  end
end
