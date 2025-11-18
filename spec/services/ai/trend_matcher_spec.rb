require "rails_helper"

RSpec.describe Ai::TrendMatcher do
  let(:subforem) { create(:subforem) }
  let(:article) { create(:article, subforem_id: subforem.id) }
  let(:trend) { create(:trend, subforem: subforem, expiry_date: 1.month.from_now) }
  let(:expired_trend) { create(:trend, subforem: subforem, expiry_date: 1.month.ago) }

  describe "#find_matching_trend" do
    context "when AI key is not present" do
      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return(nil)
        trend # Create a current trend
      end

      it "returns nil" do
        matcher = described_class.new(article)
        expect(matcher.find_matching_trend).to be_nil
      end

      it "does not create an AI client" do
        expect(Ai::Base).not_to receive(:new)
        matcher = described_class.new(article)
        matcher.find_matching_trend
      end

      it "does not query for trends" do
        expect(Trend).not_to receive(:current)
        matcher = described_class.new(article)
        matcher.find_matching_trend
      end
    end

    context "when article has no subforem" do
      let(:article) { create(:article, subforem_id: nil) }

      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
      end

      it "returns nil" do
        matcher = described_class.new(article)
        expect(matcher.find_matching_trend).to be_nil
      end

      it "does not query for trends" do
        expect(Trend).not_to receive(:current)
        matcher = described_class.new(article)
        matcher.find_matching_trend
      end
    end

    context "when no current trends exist" do
      before do
        expired_trend # Create expired trend
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
      end

      it "returns nil" do
        matcher = described_class.new(article)
        expect(matcher.find_matching_trend).to be_nil
      end

      it "does not create an AI client" do
        expect(Ai::Base).not_to receive(:new)
        matcher = described_class.new(article)
        matcher.find_matching_trend
      end

      it "does not check expired trends" do
        matcher = described_class.new(article)
        result = matcher.find_matching_trend
        expect(result).to be_nil
        expect(expired_trend.expired?).to be true
      end

      context "when trends exist for other subforems" do
        let(:other_subforem) { create(:subforem) }
        let(:other_trend) { create(:trend, subforem: other_subforem, expiry_date: 1.month.from_now) }

        before do
          other_trend
        end

        it "does not return trends from other subforems" do
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to be_nil
        end
      end
    end

    context "when current trends exist" do
      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
        trend # Ensure trend exists
      end

      context "when article matches a trend" do
        before do
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
          allow(ai_client).to receive(:call).and_return("YES")
        end

        it "returns the matching trend" do
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to eq(trend)
        end

        it "calls AI client with a prompt" do
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
          expect(ai_client).to receive(:call).with(a_string_including("Article to Analyze")).and_return("YES")
          matcher = described_class.new(article)
          matcher.find_matching_trend
        end

        it "includes article title and body in the prompt" do
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
          expect(ai_client).to receive(:call) do |prompt|
            expect(prompt).to include(article.title)
            expect(prompt).to include(article.body_markdown)
            "YES"
          end
          matcher = described_class.new(article)
          matcher.find_matching_trend
        end

        it "includes trend information in the prompt" do
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
          expect(ai_client).to receive(:call) do |prompt|
            expect(prompt).to include(trend.short_title)
            expect(prompt).to include(trend.public_description)
            expect(prompt).to include(trend.full_content_description)
            "YES"
          end
          matcher = described_class.new(article)
          matcher.find_matching_trend
        end

        context "when multiple trends exist" do
          let(:trend2) { create(:trend, subforem: subforem, expiry_date: 1.month.from_now) }
          let(:trend3) { create(:trend, subforem: subforem, expiry_date: 1.month.from_now) }

          before do
            trend2
            trend3
          end

          it "returns the first matching trend" do
            ai_client = instance_double(Ai::Base)
            allow(Ai::Base).to receive(:new).and_return(ai_client)
            # First trend matches, so it should return that one
            allow(ai_client).to receive(:call).and_return("YES")
            matcher = described_class.new(article)
            result = matcher.find_matching_trend
            expect(result).to eq(trend)
          end

          it "stops checking after finding the first match" do
            ai_client = instance_double(Ai::Base)
            allow(Ai::Base).to receive(:new).and_return(ai_client)
            # Should only be called once for the first trend
            expect(ai_client).to receive(:call).once.and_return("YES")
            matcher = described_class.new(article)
            matcher.find_matching_trend
          end

          it "checks subsequent trends if first doesn't match" do
            ai_client = instance_double(Ai::Base)
            allow(Ai::Base).to receive(:new).and_return(ai_client)
            # First trend doesn't match, second does
            allow(ai_client).to receive(:call).and_return("NO", "YES")
            matcher = described_class.new(article)
            result = matcher.find_matching_trend
            expect(result).to eq(trend2)
          end
        end
      end

      context "when article does not match any trend" do
        before do
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
          allow(ai_client).to receive(:call).and_return("NO")
        end

        it "returns nil" do
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to be_nil
        end

        it "still calls the AI client" do
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
          expect(ai_client).to receive(:call).and_return("NO")
          matcher = described_class.new(article)
          matcher.find_matching_trend
        end
      end

      context "when AI response is ambiguous" do
        before do
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
        end

        it "returns nil for blank response" do
          allow(ai_client).to receive(:call).and_return("")
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to be_nil
        end

        it "returns nil for whitespace-only response" do
          allow(ai_client).to receive(:call).and_return("   \n  ")
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to be_nil
        end

        it "handles case-insensitive YES response" do
          allow(ai_client).to receive(:call).and_return("yes")
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to eq(trend)
        end

        it "handles YES with extra whitespace" do
          allow(ai_client).to receive(:call).and_return("  YES  ")
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to eq(trend)
        end

        it "returns nil for partial match like 'YES BUT'" do
          allow(ai_client).to receive(:call).and_return("YES BUT")
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to be_nil
        end
      end

      context "when AI call fails" do
        before do
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
          allow(ai_client).to receive(:call).and_raise(StandardError.new("AI error"))
        end

        it "returns nil and logs error" do
          expect(Rails.logger).to receive(:error).with(a_string_including("AI trend matching failed"))
          matcher = described_class.new(article)
          expect(matcher.find_matching_trend).to be_nil
        end

        it "includes article and trend IDs in error log" do
          expect(Rails.logger).to receive(:error) do |message|
            expect(message).to include(article.id.to_s)
            expect(message).to include(trend.id.to_s)
          end
          matcher = described_class.new(article)
          matcher.find_matching_trend
        end

        it "continues checking other trends after a failure" do
          trend2 = create(:trend, subforem: subforem, expiry_date: 1.month.from_now)
          ai_client = instance_double(Ai::Base)
          allow(Ai::Base).to receive(:new).and_return(ai_client)
          # First trend fails, second succeeds
          call_count = 0
          allow(ai_client).to receive(:call) do
            call_count += 1
            if call_count == 1
              raise StandardError.new("AI error")
            else
              "YES"
            end
          end
          matcher = described_class.new(article)
          result = matcher.find_matching_trend
          expect(result).to eq(trend2)
        end
      end
    end
  end
end

