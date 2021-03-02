require "spec_helper"

module RSpec
  module Mocks
    RSpec.describe ErrorGenerator do
      context "when inserting a backtrace line" do
        def has_java_frames?
          yield
        rescue RSpec::Mocks::MockExpectationError => e
          e.backtrace.grep(/\.java:/).any?
        else
          raise "got no exception"
        end

        it "produces stacktraces that match how `raise` produces stacktraces (on JRuby `caller` and `raise` can differ about the presence of java frames)" do
          raise_has_java_frames = has_java_frames? { raise RSpec::Mocks::MockExpectationError }

          eg_has_java_frames = has_java_frames? do
            ErrorGenerator.new.send(:__raise, "message", "foo.rb:1")
          end

          expect(raise_has_java_frames).to eq eg_has_java_frames
        end
      end

      def unexpected_failure_message_for(object_description)
        /received unexpected message :bees with \(#{object_description}\)/
      end

      describe "formatting arguments" do
        it 'formats time objects with increased precision' do
          time = Time.utc(1969, 12, 31, 19, 01, 40, 101)
          expected_output = "1969-12-31 19:01:40.000101"

          o = double(:double)
          expect {
            o.bees(time)
          }.to fail_including(expected_output)
        end

        context "on non-matcher objects that define #description" do
          it "does not use the object's description" do
            o = double(:double, :description => "Friends")
            expect {
              o.bees(o)
            }.to fail_with(unexpected_failure_message_for(o.inspect))
          end
        end

        context "on matcher objects" do
          context "that define description" do
            it "uses the object's description" do
              d = double(:double)
              o = fake_matcher(Object.new)
              expect {
                d.bees(o)
              }.to raise_error(unexpected_failure_message_for(o.description))
            end
          end

          context "that do not define description" do
            it "does not use the object's description" do
              d = double(:double)
              o = Class.new do
                def self.name
                  "RSpec::Mocks::ArgumentMatchers::"
                end
              end.new

              expect(RSpec::Support.is_a_matcher?(o)).to be true

              expect {
                d.bees(o)
              }.to fail_with(unexpected_failure_message_for(o.inspect))
            end
          end

          context "on default method stub" do
            it "error message display starts in new line" do
              d = double(:double)
              allow(d).to receive(:foo).with({})
              expect { d.foo([]) }.to fail_with(/\nDiff/)
            end
          end
        end
      end
    end
  end
end
