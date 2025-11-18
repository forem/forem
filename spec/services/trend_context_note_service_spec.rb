require "rails_helper"

RSpec.describe TrendContextNoteService do
  let(:subforem) { create(:subforem) }
  let(:article) { create(:article, subforem_id: subforem.id) }
  let(:trend) { create(:trend, subforem: subforem, expiry_date: 1.month.from_now, short_title: "AI Revolution") }

  describe ".check_and_create_context_note" do
    context "when AI key is not present" do
      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return(nil)
      end

      it "returns nil" do
        expect(described_class.check_and_create_context_note(article)).to be_nil
      end

      it "does not create a TrendMatcher instance" do
        expect(Ai::TrendMatcher).not_to receive(:new)
        described_class.check_and_create_context_note(article)
      end
    end

    context "when article has no subforem" do
      let(:article) { create(:article, subforem_id: nil) }

      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
      end

      it "returns nil" do
        expect(described_class.check_and_create_context_note(article)).to be_nil
      end

      it "does not create a TrendMatcher instance" do
        expect(Ai::TrendMatcher).not_to receive(:new)
        described_class.check_and_create_context_note(article)
      end
    end

    context "when article already has a context note" do
      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
      end

      context "when context note is tag-based" do
        let(:tag) { create(:tag) }

        before do
          create(:context_note, article: article, tag: tag)
        end

        it "returns nil without checking trends" do
          expect(Ai::TrendMatcher).not_to receive(:new)
          expect(described_class.check_and_create_context_note(article)).to be_nil
        end

        it "does not create a new context note" do
          expect do
            described_class.check_and_create_context_note(article)
          end.not_to change(ContextNote, :count)
        end
      end

      context "when context note is trend-based" do
        let(:other_trend) { create(:trend, subforem: subforem, expiry_date: 1.month.from_now) }

        before do
          create(:context_note, article: article, trend: other_trend)
        end

        it "returns nil without checking trends" do
          expect(Ai::TrendMatcher).not_to receive(:new)
          expect(described_class.check_and_create_context_note(article)).to be_nil
        end

        it "does not create a new context note" do
          expect do
            described_class.check_and_create_context_note(article)
          end.not_to change(ContextNote, :count)
        end
      end
    end

    context "when no current trends exist for subforem" do
      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
        # Create an expired trend to ensure no current trends exist
        create(:trend, subforem: subforem, expiry_date: 1.month.ago)
      end

      it "returns nil without creating a TrendMatcher" do
        expect(Ai::TrendMatcher).not_to receive(:new)
        expect(described_class.check_and_create_context_note(article)).to be_nil
      end

      it "does not create a context note" do
        expect do
          described_class.check_and_create_context_note(article)
        end.not_to change(ContextNote, :count)
      end

      it "does not query for trends in other subforems" do
        other_subforem = create(:subforem)
        other_trend = create(:trend, subforem: other_subforem, expiry_date: 1.month.from_now)

        expect(described_class.check_and_create_context_note(article)).to be_nil
        expect(other_trend.reload).to be_present
      end
    end

    context "when a matching trend is found" do
      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
        # Ensure there's a current trend for the subforem
        trend # Create the trend
        matcher = instance_double(Ai::TrendMatcher)
        allow(Ai::TrendMatcher).to receive(:new).with(article).and_return(matcher)
        allow(matcher).to receive(:find_matching_trend).and_return(trend)
      end

      it "creates a context note with the trend's short_title" do
        expect do
          described_class.check_and_create_context_note(article)
        end.to change(ContextNote, :count).by(1)

        context_note = ContextNote.last
        expect(context_note.article).to eq(article)
        expect(context_note.trend).to eq(trend)
        expect(context_note.body_markdown).to eq("AI Revolution")
        expect(context_note.tag).to be_nil
      end

      it "does not create duplicate context notes for the same trend" do
        create(:context_note, article: article, trend: trend)

        expect do
          described_class.check_and_create_context_note(article)
        end.not_to change(ContextNote, :count)
      end

      it "returns existing context note if one exists for the same trend" do
        existing_note = create(:context_note, article: article, trend: trend)
        result = described_class.check_and_create_context_note(article)
        expect(result).to eq(existing_note)
      end

      it "creates a context note with processed_html" do
        described_class.check_and_create_context_note(article)
        context_note = ContextNote.last
        expect(context_note.processed_html).to be_present
        expect(context_note.processed_html).not_to be_blank
      end
    end

    context "when no matching trend is found" do
      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
        # Ensure there's a current trend for the subforem (but it won't match)
        trend # Create the trend
        matcher = instance_double(Ai::TrendMatcher)
        allow(Ai::TrendMatcher).to receive(:new).with(article).and_return(matcher)
        allow(matcher).to receive(:find_matching_trend).and_return(nil)
      end

      it "does not create a context note" do
        expect do
          described_class.check_and_create_context_note(article)
        end.not_to change(ContextNote, :count)
      end

      it "returns nil" do
        expect(described_class.check_and_create_context_note(article)).to be_nil
      end

      it "still calls the TrendMatcher to check for matches" do
        matcher = instance_double(Ai::TrendMatcher)
        expect(Ai::TrendMatcher).to receive(:new).with(article).and_return(matcher)
        expect(matcher).to receive(:find_matching_trend).and_return(nil)
        described_class.check_and_create_context_note(article)
      end
    end

    context "when an error occurs" do
      before do
        allow(Ai::Base).to receive(:DEFAULT_KEY).and_return("test-key")
        # Ensure there's a current trend for the subforem
        trend # Create the trend
        allow(Ai::TrendMatcher).to receive(:new).and_raise(StandardError.new("Test error"))
      end

      it "logs the error and returns nil" do
        expect(Rails.logger).to receive(:error).with(a_string_including("Failed to check trend matching"))
        expect(described_class.check_and_create_context_note(article)).to be_nil
      end

      it "includes article ID in error log" do
        expect(Rails.logger).to receive(:error) do |message|
          expect(message).to include(article.id.to_s)
        end
        described_class.check_and_create_context_note(article)
      end
    end
  end
end

