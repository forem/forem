require "rails_helper"

RSpec.describe Ai::FunctionConfig do
  before do
    stub_const("Ai::Base::DEFAULT_KEY", "gemini-key")
    stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", "typesafe-key")
  end

  describe ".selection_for" do
    it "uses the built-in Gemini default when nothing is configured" do
      selection = described_class.selection_for(:article_spam_check)

      expect(selection).to have_attributes(option: "default", provider: :gemini, model: nil)
      expect(selection.gemini_model("builtin-model")).to eq("builtin-model")
    end

    it "uses Jev when configured and the TypeSafe key is present" do
      Settings::AiFunctions.set_global_function_models("article_spam_check" => "jev")

      selection = described_class.selection_for(:article_spam_check)

      expect(selection).to be_jev
      expect(selection.model).to eq(Ai::TypeSafe::Client::DEFAULT_MODEL)
    end

    it "falls back to the default when Jev is configured but the TypeSafe key is missing" do
      stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", nil)
      Settings::AiFunctions.set_global_function_models("article_spam_check" => "jev")

      expect(described_class.selection_for(:article_spam_check))
        .to have_attributes(option: "default", provider: :gemini)
    end

    it "overrides the Gemini model for a function" do
      Settings::AiFunctions.set_global_function_models("article_summary" => "gemini_lite")

      expect(described_class.gemini_model_for(:article_summary)).to eq(Ai::Base::DEFAULT_LITE_MODEL)
      expect(described_class.gemini_model_for(:context_note)).to eq(Ai::Base::DEFAULT_MODEL)
    end

    it "never selects Jev for a text-generation function, even if stored" do
      Settings::AiFunctions.set_global_function_models("article_summary" => "jev")

      expect(described_class.selection_for(:article_summary)).to be_gemini
    end

    it "keeps functions independent" do
      Settings::AiFunctions.set_global_function_models("comment_spam_check" => "jev")

      expect(described_class.jev?(:comment_spam_check)).to be(true)
      expect(described_class.jev?(:article_spam_check)).to be(false)
    end

    it "raises on unknown functions" do
      expect { described_class.selection_for(:nope) }.to raise_error(Ai::FunctionRegistry::UnknownFunctionError)
    end
  end

  describe ".available?" do
    it "requires the Gemini key for the default model" do
      stub_const("Ai::Base::DEFAULT_KEY", nil)

      expect(described_class.available?(:content_moderation)).to be(false)
    end

    it "lets a Jev-selected function run without a Gemini key" do
      stub_const("Ai::Base::DEFAULT_KEY", nil)
      Settings::AiFunctions.set_global_function_models("content_moderation" => "jev")

      expect(described_class.available?(:content_moderation)).to be(true)
    end
  end

  describe ".options_for" do
    it "offers Jev only for judgment functions" do
      expect(described_class.options_for(:article_spam_check)).to eq(%w[default gemini_pro gemini_lite jev])
      expect(described_class.options_for(:article_summary)).to eq(%w[default gemini_pro gemini_lite])
    end

    it "offers nothing for fixed-model functions" do
      expect(described_class.options_for(:embeddings)).to eq([])
    end
  end

  describe ".sanitize" do
    it "keeps only known functions with supported options and drops defaults" do
      sanitized = described_class.sanitize(
        "article_spam_check" => "jev",
        "article_summary" => "jev",
        "context_note" => "gemini_lite",
        "comment_spam_check" => "default",
        "embeddings" => "gemini_pro",
        "not_a_function" => "jev",
      )

      expect(sanitized).to eq("article_spam_check" => "jev", "context_note" => "gemini_lite")
    end
  end

  it "registers every Jev function with a Jev option" do
    Ai::FunctionRegistry.all.select(&:jev?).each do |function|
      expect(described_class.options_for(function)).to include("jev")
    end
  end
end
