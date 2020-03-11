require "rails_helper"

RSpec.describe "/internal/tags", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag_moderator) { create(:user) }
  let!(:tag) { create(:tag) }
  let(:listener) { :internal }

  before do
    sign_in super_admin
    Audit::Subscribe.listen listener
  end

  after do
    Audit::Subscribe.forget listener
  end

  def update_params(tag_moderator_id)
    {
      tag: {
        tag_moderator_id: tag_moderator_id
      }
    }
  end

  describe "POST /internal/tag/:id" do
    it "creates entry for #update action" do
      allow(AssignTagModerator).to receive(:add_tag_moderators)

      sidekiq_perform_enqueued_jobs do
        put "/internal/tags/#{tag.id}", params: update_params(tag_moderator.id.to_s)
        log = AuditLog.where(user_id: super_admin.id, slug: :update)
        expected = update_params(tag_moderator.id.to_s)[:tag]

        expect(log.first.data.symbolize_keys).to eq expected
        expect(log.count).to eq(1)
      end
    end
  end
end
