module RSpec
  module Matchers
    RSpec.describe EnglishPhrasing do
      describe ".split_words" do
        it "replaces underscores with spaces" do
          expect(
            described_class.split_words(:banana_creme_pie)
          ).to eq("banana creme pie")
        end

        it "first casts its argument to string" do
          arg = double(:to_s => "banana")
          expect(described_class.split_words(arg)).to eq("banana")
        end
      end

      describe ".list" do
        context "given nil" do
          it "returns value from inspect, and a leading space" do
            expect(described_class.list(nil)).to eq(" nil")
          end
        end

        context "given a Struct" do
          it "returns value from inspect, and a leading space" do
            banana = Struct.new("Banana", :flavor).new
            expect(
              described_class.list(banana)
            ).to eq(" #{banana.inspect}")
          end
        end

        context "given a Hash" do
          it "returns value from inspect, and a leading space" do
            banana = { :flavor => 'Banana' }
            expect(
              described_class.list(banana)
            ).to eq(" #{banana.inspect}")
          end
        end

        context "given an Enumerable other than a Hash" do
          before do
            allow(RSpec::Support::ObjectFormatter).to(
              receive(:format).and_return("Banana")
            )
          end

          context "with zero items" do
            it "returns the empty string" do
              expect(described_class.list([])).to eq("")
            end
          end

          context "with one item" do
            let(:list) { [double] }
            it "returns description, and a leading space" do
              expect(described_class.list(list)).to eq(" Banana")
              expect(RSpec::Support::ObjectFormatter).to(
                have_received(:format).once
              )
            end
          end

          context "with two items" do
            let(:list) { [double, double] }
            it "returns descriptions, and a leading space" do
              expect(described_class.list(list)).to eq(" Banana and Banana")
              expect(RSpec::Support::ObjectFormatter).to(
                have_received(:format).twice
              )
            end
          end

          context "with three items" do
            let(:list) { [double, double, double] }
            it "returns descriptions, and a leading space" do
              expect(
                described_class.list(list)
              ).to eq(" Banana, Banana, and Banana")
              expect(RSpec::Support::ObjectFormatter).to(
                have_received(:format).exactly(3).times
              )
            end
          end
        end
      end
    end
  end
end
