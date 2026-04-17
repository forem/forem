require "rails_helper"

RSpec.describe UserSubscriptionTag, type: :liquid_tag do
  let(:subscriber) { create(:user) }
  let(:author) { create(:user) }
  let(:article_with_user_subscription_tag) do
    create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
  end

  before do
    Liquid::Template.register_tag("user_subscription", described_class)

    # Stub roles because adding them normally can cause flaky specs
    allow(author).to receive(:has_role?).and_call_original
    allow(author).to receive(:has_role?).with(:restricted_liquid_tag, LiquidTags::UserSubscriptionTag).and_return(true)
  end

  describe ".user_authorization_method_name" do
    subject(:result) { described_class.user_authorization_method_name }

    it { is_expected.to eq(:user_subscription_tag_available?) }
  end

  context "when rendering" do
    it "renders default data correctly" do
      source = create(:article, user: author)
      liquid_tag_options = { source: source, user: source.user }
      cta_text = "Some sweet CTA text"
      liquid_tag = Liquid::Template.parse("{% user_subscription #{cta_text} %}", liquid_tag_options).render
      expect(liquid_tag).to include(CGI.escapeHTML(cta_text))
      expect(liquid_tag).to include(CGI.escapeHTML(author.username))
      expect(liquid_tag).to include(CGI.escapeHTML(author.profile_image_90))
    end
  end
end
