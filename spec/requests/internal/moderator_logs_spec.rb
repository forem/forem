require "rails_helper"

RSpec.describe "/internal/tags", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag_moderator) { create(:user) }
  let!(:tag) { create(:tag) }
  let(:listener) { :moderator }

  before do
    sign_in super_admin
    Audit::Subscribe.listen listener
  end

  after do
    Audit::Subscribe.forget listener
  end

  describe "PUT /internal/tag/:id" do
    it "creates entry for #update action" do
      put internal_tag_path(tag.id), params: { id: tag.id, tag: { short_summary: Faker::Hipster.sentence } }

      log = AuditLog.where(user_id: super_admin.id, slug: :update)
      expect(log.count).to eq(1)
    end
  end
end
