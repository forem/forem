require "rails_helper"

RSpec.describe LiquidTagBase, type: :liquid_tag do
  # #new and #initialize are both private methods in Liquid::Tag, which is what
  # LiquidTagBase inherits from, so we treat this class as a liquid tag itself.
  before { Liquid::Template.register_tag("liquid_tag_base", described_class) }

  context "when VALID_CONTEXTS are defined" do
    before { stub_const("#{described_class}::VALID_CONTEXTS", %w[Article]) }

    it "raises an error for invalid contexts" do
      source = create(:comment)
      expect do
        liquid_tag_options = { source: source, user: source.user }
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.to raise_error(LiquidTags::Errors::InvalidParseContext)
    end

    it "doesn't raise an error for valid contexts" do
      source = create(:article)
      expect do
        liquid_tag_options = { source: source, user: source.user }
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.not_to raise_error
    end
  end

  context "when VALID_CONTEXTS aren't defined" do
    it "does not validate contexts" do
      source = create(:article)
      liquid_tag_options = { source: source, user: source.user }
      expect do
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.not_to raise_error
    end
  end

  context "when .user_authorization_method_name is not nil" do
    it "raises an error for invalid roles" do
      source = create(:article)
      liquid_tag_options = { source: source, user: source.user }
      allow(described_class).to receive(:user_authorization_method_name).and_return(:admin?)
      expect do
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "doesn't raise an error for valid roles" do
      author = create(:user, :admin)
      source = create(:article, user: author)
      liquid_tag_options = { source: source, user: source.user }
      allow(described_class).to receive(:user_authorization_method_name).and_return(:admin?)
      expect do
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.not_to raise_error
    end
  end

  context "when .user_authorization_method_name is nil" do
    it "doesn't validate roles" do
      source = create(:article)
      liquid_tag_options = { source: source, user: source.user }
      allow(described_class).to receive(:user_authorization_method_name).and_return(nil)
      expect do
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.not_to raise_error
    end
  end
end
