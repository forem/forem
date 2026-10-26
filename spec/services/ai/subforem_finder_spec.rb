require "rails_helper"

RSpec.describe Ai::SubforemFinder, type: :service do
  let!(:current_subforem) { create(:subforem, domain: "current.example.com") }
  let!(:rust_subforem) { create(:subforem, domain: "rust.example.com", discoverable: true) }
  let!(:design_subforem) { create(:subforem, domain: "design.example.com", discoverable: true) }
  let(:article) { create(:article, subforem_id: current_subforem.id, title: "Ownership in Rust") }

  before do
    allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
    allow(Settings::Community).to receive(:community_description) do |subforem_id:|
      subforem_id == rust_subforem.id ? "All about the Rust language" : "Visual and product design"
    end
    allow(Subforem).to receive(:misc_subforem).and_return(nil)
  end

  describe "#find_appropriate_subforem with Gemini (default)" do
    it "returns the subforem whose domain the AI names" do
      allow(Ai::Base).to receive(:new).and_return(instance_double(Ai::Base, call: "rust.example.com"))

      expect(described_class.new(article).find_appropriate_subforem).to eq(rust_subforem.id)
    end
  end

  describe "#find_appropriate_subforem with Jev selected" do
    let(:rust_key) { "subforem_#{rust_subforem.id}" }

    before do
      allow(Ai::Base).to receive(:new)
      enable_jev_for(:subforem_matching)
    end

    it "picks the chosen subforem when it clearly fits" do
      requests = stub_jev("best_home" => [rust_key, 0.9], "fits::#{rust_key}" => 0.9)

      expect(described_class.new(article).find_appropriate_subforem).to eq(rust_subforem.id)
      expect(Ai::Base).not_to have_received(:new)
      criteria = requests.first[:questions][:best_home][:criteria]
      expect(criteria.keys).to contain_exactly(rust_key, "subforem_#{design_subforem.id}", "none")
      expect(criteria[rust_key]).to eq(domain: "rust.example.com", content_guidelines: "All about the Rust language")
    end

    it "returns nothing when the model chooses none" do
      stub_jev("best_home" => ["none", 0.9], "fits::#{rust_key}" => 0.9)

      expect(described_class.new(article).find_appropriate_subforem).to be_nil
    end

    it "returns nothing when the chosen subforem does not clearly fit on its own" do
      stub_jev("best_home" => [rust_key, 0.9], "fits::#{rust_key}" => 0.4)

      expect(described_class.new(article).find_appropriate_subforem).to be_nil
    end

    it "returns nothing when the choice is uncertain" do
      stub_jev("best_home" => [rust_key, 0.3], "fits::#{rust_key}" => 0.9)

      expect(described_class.new(article).find_appropriate_subforem).to be_nil
    end
  end
end
