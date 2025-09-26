require 'rails_helper'

# Specs for the Ai::ContextNoteGenerator service
RSpec.describe Ai::ContextNoteGenerator, type: :service do
  # Using factories to create test data for an article and a tag
  let(:article) { create(:article, title: "The Future of AI") }
  let(:tag) { create(:tag, context_note_instructions: "Summarize the key points of the article.") }
  let(:generator) { described_class.new(article, tag) }

  # Mocking the AI client to avoid actual API calls during tests
  let(:ai_client_double) { instance_double(Ai::Base) }
  let(:ai_response) { "This is a summary of the key points." }

  # Stubbing the Ai::Base.new call to return our mock client
  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client_double)
    allow(ai_client_double).to receive(:call).and_return(ai_response)
  end

  ##
  # Test suite for the #call method
  #
  describe "#call" do
    context "when all data is valid" do
      it "creates a context note with the AI response" do
        # We expect ContextNote.create! to be called once
        expect(ContextNote).to receive(:create!).with(
          body_markdown: ai_response,
          article: article,
          tag: tag
        )
        generator.call
      end

      it "returns the created context note" do
        # The method should return the newly created note
        note = generator.call
        expect(note).to be_a(ContextNote)
        expect(note.body_markdown).to eq(ai_response)
      end
    end

    context "when the AI response is invalid" do
      it "does not create a context note if response is 'INVALID'" do
        allow(ai_client_double).to receive(:call).and_return("INVALID")
        # We expect ContextNote.create! not to be called
        expect(ContextNote).not_to receive(:create!)
        generator.call
      end

      it "does not create a context note if response is blank" do
        allow(ai_client_double).to receive(:call).and_return("   ")
        expect(ContextNote).not_to receive(:create!)
        generator.call
      end
    end

    context "when initialization data is missing" do
      it "returns nil if article is not present" do
        generator = described_class.new(nil, tag)
        expect(generator.call).to be_nil
      end

      it "returns nil if tag is not present" do
        generator = described_class.new(article, nil)
        expect(generator.call).to be_nil
      end

      it "returns nil if tag context note instructions are blank" do
        tag.update!(context_note_instructions: "")
        generator = described_class.new(article, tag)
        expect(generator.call).to be_nil
      end
    end

    context "when an error occurs" do
      it "logs the error and does not crash" do
        # Forcing the AI client to raise a StandardError
        error = StandardError.new("AI service is down")
        allow(ai_client_double).to receive(:call).and_raise(error)

        # We expect the Rails logger to receive the error message
        expect(Rails.logger).to receive(:error).with("Context Note Generation failed: #{error}")
        # The call should not re-raise the error
        expect { generator.call }.not_to raise_error
      end
    end
  end

  ##
  # Test suite for the #build_prompt method
  #
  describe "#build_prompt" do
    it "constructs a detailed prompt with article and tag info" do
      prompt = generator.build_prompt
      expect(prompt).to include("You are an AI assistant that generates context notes for articles.")
      expect(prompt).to include("The article is titled \"#{article.title}\"")
      expect(prompt).to include(article.body_markdown)
      expect(prompt).to include("please generate a context note that follows these instructions:")
      expect(prompt).to include(tag.context_note_instructions)
      expect(prompt).to include("return only the word \"INVALID\" and nothing else.")
    end

    it "returns nil if the tag instructions are blank" do
      tag.update!(context_note_instructions: "  ")
      generator = described_class.new(article, tag)
      expect(generator.build_prompt).to be_nil
    end
  end
end