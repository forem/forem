require "rails_helper"

RSpec.describe AdminMenu do
  describe ".nested_menu_items_from_request" do
    subject(:method_call) { described_class.nested_menu_items_from_request(request) }

    let(:request) { instance_double("ActionDispatch::Request", path: path) }
    let(:path) { "/admin" }

    context "when path is /admin/moderation/feedback_messages" do
      let(:path) { "/admin/moderation/feedback_messages" }

      it { is_expected.not_to be_present }
    end

    context "when path is /admin/content_manager/badge_achievements" do
      let(:path) { "/admin/content_manager/badge_achievements" }

      let(:badges_node) do
        described_class::ITEMS[:content_manager]
          .fetch(:children)
          .detect { |ch| ch.fetch(:name) == "badges" }
      end

      it { is_expected.to eq(badges_node) }
    end
  end
end
