require "rails_helper"

RSpec.describe "/admin/content_manager/tags", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag_moderator) { build_stubbed(:user) }
  let!(:tag) { create(:tag) }
  let(:listener) { :moderator }

  before do
    sign_in super_admin
    Audit::Subscribe.listen listener
  end

  after do
    Audit::Subscribe.forget listener
  end

  describe "PUT /admin/content_manager/tags/:id" do
    it "creates entry for #update action" do
      put admin_tag_path(tag.id), params: { id: tag.id, tag: { short_summary: Faker::Hipster.sentence } }

      log = AuditLog.where(user_id: super_admin.id, slug: :update)
      expect(log.count).to eq(1)
    end
  end
end
