require "rails_helper"

RSpec.describe AdminMenu do
  describe ".nested_menu_items_from_request" do
    subject(:method_call) { described_class.nested_menu_items_from_request(request) }

    let(:request) { instance_double(ActionDispatch::Request, path: path) }
    let(:path) { "/admin" }

    context "when path is /admin/moderation/feedback_messages" do
      let(:path) { "/admin/moderation/feedback_messages" }

      it { is_expected.not_to be_present }
    end

    context "when path is /admin/content_manager/badge_achievements" do
      let(:path) { "/admin/content_manager/badge_achievements" }

      let(:badges_node) do
        described_class::ITEMS[:content_manager].children
          .detect { |ch| ch.name == "badges" }
      end

      it { is_expected.to eq(badges_node) }
    end
  end

  describe ".navigation_items" do
    subject(:navigation_items) { described_class.navigation_items }

    it { is_expected.to be_a(Hash) }
  end

  describe "scope :content_manager" do
    subject(:content_manager) { described_class.navigation_items.fetch(:content_manager) }

    it { is_expected.to be_a(Menu::Scope) }
  end

  describe "scope :content_managers's posts item" do
    subject(:posts) { content_manager.children.detect { |child| child.name == "posts" } }

    let(:content_manager) { described_class.navigation_items.fetch(:content_manager) }

    it { is_expected.to be_visible }
  end

  describe "scope :content_managers's spaces item" do
    subject(:spaces) { content_manager.children.detect { |child| child.name == "spaces" } }

    let(:content_manager) { described_class.navigation_items.fetch(:content_manager) }

    it { is_expected.to be_visible }
  end

  describe "scope :customization" do
    subject(:content_manager) { described_class.navigation_items.fetch(:customization) }

    it { is_expected.to be_a(Menu::Scope) }
    it { is_expected.to have_multiple_children }
    it { is_expected.to have_children }
  end

  describe "scope :admin_team" do
    subject(:content_manager) { described_class.navigation_items.fetch(:admin_team) }

    it { is_expected.not_to have_multiple_children }
    it { is_expected.to have_children }
  end

  describe "scope :customization's profile field" do
    subject(:profile_field) { customization.children.detect { |child| child.name == "profile fields" } }

    let(:customization) { described_class.navigation_items.fetch(:customization) }

    it { is_expected.to be_a(Menu::Item) }
    it { is_expected.to be_visible }
  end

  describe "scope :apps" do
    subject(:listing) { apps.children.detect { |child| child.name == "listings" } }

    let(:apps) { described_class.navigation_items.fetch(:apps) }

    context "when Listing.feature_enabled? is true" do
      before { allow(Listing).to receive(:feature_enabled?).and_return(true) }

      it { is_expected.to be_visible }
    end

    context "when Listing.feature_enabled? is false" do
      before { allow(Listing).to receive(:feature_enabled?).and_return(false) }

      it { is_expected.not_to be_visible }
    end
  end
end
