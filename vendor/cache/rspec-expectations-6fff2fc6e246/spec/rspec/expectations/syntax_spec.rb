module RSpec
  module Expectations
    RSpec.describe Syntax do
      context "when passing a message to an expectation" do
        let(:warner) { ::Kernel }

        let(:string_like_object) do
          Struct.new(:to_str, :to_s).new(*(["Ceci n'est pas une Chaine."]*2))
        end

        let(:insufficiently_string_like_object) do
          Struct.new(:to_s).new("Ceci n'est pas une Chaine.")
        end

        let(:callable_object) do
          Struct.new(:call).new("Ceci n'est pas une Chaine.")
        end

        describe "expect(...).to" do
          it "prints a warning when the message object isn't a String" do
            expect(warner).to receive(:warn).with(/ignoring.*message/)
            expect(3).to eq(3), :not_a_string
          end

          it "doesn't print a warning when message is a String" do
            expect(warner).not_to receive(:warn)
            expect(3).to eq(3), "a string"
          end

          it "doesn't print a warning when message responds to to_str" do
            expect(warner).not_to receive(:warn)
            expect(3).to eq(3), string_like_object
          end

          it "prints a warning when the message object handles to_s but not to_str" do
            expect(warner).to receive(:warn).with(/ignoring.*message/)
            expect(3).to eq(3), insufficiently_string_like_object
          end

          it "doesn't print a warning when message responds to call" do
            expect(warner).not_to receive(:warn)
            expect(3).to eq(3), callable_object
          end
        end

        describe "expect(...).not_to" do
          it "prints a warning when the message object isn't a String" do
            expect(warner).to receive(:warn).with(/ignoring.*message/)
            expect(3).not_to eq(4), :not_a_string
          end

          it "doesn't print a warning when message is a String" do
            expect(warner).not_to receive(:warn)
            expect(3).not_to eq(4), "a string"
          end

          it "doesn't print a warning when message responds to to_str" do
            expect(warner).not_to receive(:warn)
            expect(3).not_to eq(4), string_like_object
          end

          it "prints a warning when the message object handles to_s but not to_str" do
            expect(warner).to receive(:warn).with(/ignoring.*message/)
            expect(3).not_to eq(4), insufficiently_string_like_object
          end

          it "doesn't print a warning when message responds to call" do
            expect(warner).not_to receive(:warn)
            expect(3).not_to eq(4), callable_object
          end
        end
      end

      describe "enabling the should syntax on something other than the default syntax host" do
        include_context "with the default expectation syntax"

        it "continues to warn about the should syntax" do
          my_host = Class.new
          expect(RSpec).to receive(:deprecate)
          Syntax.enable_should(my_host)

          3.should eq 3
        end
      end
    end
  end

  RSpec.describe Expectations do
    it "does not inadvertently define BasicObject on 1.8", :if => RUBY_VERSION.to_f < 1.9 do
      expect(defined?(::BasicObject)).to be nil
    end
  end
end
