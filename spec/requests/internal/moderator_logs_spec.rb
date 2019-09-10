require "rails_helper"

RSpec.describe "/internal/tags", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag_moderator) { create(:user) }
  let(:tag) { create(:tag) }
  let(:listener) { :internal }

  before do
    tag
    sign_in super_admin
    Audit::Subscribe.listen listener
  end

  after do
    Audit::Subscribe.forget listener
  end

  describe "POST /internal/tag/:id" do
    [
      {
        tag_key: :tag_moderator_id,
        name: :add_moderator
      },
      {
        tag_key: :remove_moderator_id,
        name: :remove_moderator
      },
      {
        tag_key: :short_summary,
        name: :update
      },
    ].each do |action|
      it "creates entry for #{action[:name]} action" do
        params = {
          tag: Hash[action[:tag_key], tag_moderator.id.to_s]
        }

        allow(AssignTagModerator).to receive(:add_tag_moderators)

        perform_enqueued_jobs do
          put "/internal/tags/#{tag.id}", params: params
          log = AuditLog.find_by(user_id: super_admin.id, slug: action[:name])
          expect(log.data.symbolize_keys).to eq(params[:tag])
        end
      end
    end
  end
end
