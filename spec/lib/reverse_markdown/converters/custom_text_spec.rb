require "rails_helper"

RSpec.describe ReverseMarkdown::Converters::CustomText, type: :lib do
  def create_custom_text
    ReverseMarkdown.config.github_flavored = true
    described_class.new
  end

  describe "#convert" do
    it "keeps some blankspace between lines in the same paragraph" do
      node = Nokogiri::HTML("newlines\nbecome\nspaces")
      result = create_custom_text.convert(node)
      expect(result).to eq("newlines become spaces")
    end
  end
end
