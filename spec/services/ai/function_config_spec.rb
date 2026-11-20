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
      expect(selection).to be_decision
      expect(selection).not_to be_gemini_decision
      expect(selection.model).to eq(Ai::TypeSafe::Client::DEFAULT_MODEL)
    end

    it "uses Gemini Decision 1 when configured and the Gemini key is present", :aggregate_failures do
      stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", nil)
      Settings::AiFunctions.set_global_function_models("article_spam_check" => "gemini_decision")

      selection = described_class.selection_for(:article_spam_check)

      expect(selection).to be_gemini_decision
      expect(selection).to be_decision
      expect(selection).not_to be_jev
      expect(selection.model).to eq("gemini-decision-1")
      expect(selection.gemini_model("builtin-model")).to eq("builtin-model")
      expect(selection.decision_client).to be_a(Ai::GeminiDecision::Client)
    end

    it "falls back to the default when Gemini Decision is configured but the Gemini key is missing" do
      stub_const("Ai::Base::DEFAULT_KEY", nil)
      Settings::AiFunctions.set_global_function_models("article_spam_check" => "gemini_decision")

      expect(described_class.selection_for(:article_spam_check))
        .to have_attributes(option: "default", provider: :gemini)
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

    it "never selects Jev or Gemini Decision for a text-generation function, even if stored" do
      Settings::AiFunctions.set_global_function_models("article_summary" => "jev")
      expect(described_class.selection_for(:article_summary)).to be_gemini

      Settings::AiFunctions.set_global_function_models("article_summary" => "gemini_decision")
      expect(described_class.selection_for(:article_summary)).to be_gemini
    end

    it "keeps functions independent" do
      Settings::AiFunctions.set_global_function_models("comment_spam_check" => "gemini_decision")

      expect(described_class.decision?(:comment_spam_check)).to be(true)
      expect(described_class.decision?(:article_spam_check)).to be(false)
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
    it "offers Gemini Decision and Jev only for judgment functions" do
      expect(described_class.options_for(:article_spam_check))
        .to eq(%w[default gemini_pro gemini_lite gemini_decision jev])
      expect(described_class.options_for(:article_summary)).to eq(%w[default gemini_pro gemini_lite])
    end

    it "offers Off, Gemini Decision, and Jev for decision-only functions" do
      expect(described_class.options_for(:spam_escalation)).to eq(%w[default gemini_decision jev])
      expect(described_class.option_label("default", Ai::FunctionRegistry.fetch(:spam_escalation))).to eq("Off")
      expect(described_class.option_label("gemini_decision"))
        .to eq("Gemini Decision: #{Ai::GeminiDecision::Client::DEFAULT_MODEL}")
    end

    it "offers nothing for fixed-model functions" do
      expect(described_class.options_for(:embeddings)).to eq([])
    end
  end

  describe ".option_available?" do
    it "needs no key to turn a decision-only function off and uses GEMINI_API_KEY for Gemini Decision" do
      stub_const("Ai::Base::DEFAULT_KEY", nil)

      expect(described_class.option_available?("default")).to be(false)
      expect(described_class.option_available?("gemini_decision")).to be(false)
      expect(described_class.missing_key_for("gemini_decision")).to eq("GEMINI_API_KEY")
      expect(described_class.option_available?("default", Ai::FunctionRegistry.fetch(:spam_escalation))).to be(true)
    end
  end

  describe ".sanitize" do
    it "keeps only known functions with supported options and drops defaults" do
      sanitized = described_class.sanitize(
        "article_spam_check" => "jev",
        "spam_escalation" => "gemini_decision",
        "article_summary" => "gemini_decision",
        "context_note" => "gemini_lite",
        "comment_spam_check" => "default",
        "embeddings" => "gemini_pro",
        "semantic_search_reranking" => "gemini_lite",
        "not_a_function" => "jev",
      )

      expect(sanitized).to eq(
        "article_spam_check" => "jev",
        "spam_escalation" => "gemini_decision",
        "context_note" => "gemini_lite",
      )
    end
  end

  it "registers every judgment function with both Gemini Decision and Jev options" do
    Ai::FunctionRegistry.all.select(&:jev?).each do |function|
      expect(described_class.options_for(function)).to include("gemini_decision", "jev")
    end
  end
end
