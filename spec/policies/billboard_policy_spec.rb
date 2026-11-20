require "rails_helper"

RSpec.describe BillboardPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:allowed) { [] }

  before do
    user.add_role(:single_resource_admin, Billboard)
    SubPermissions.update_grant(user: user, resource_type: "Billboard",
                                sub_permissions: SubPermissions.build(allow: allowed))
    user.reload
  end

  def missing(record, action = :save)
    described_class.new(user, record).missing_sub_permissions(action)
  end

  describe "creating a billboard" do
    it "needs nothing for an unapproved, unpublished billboard" do
      expect(missing(build(:billboard, approved: false, published: false))).to be_empty
    end

    it "needs approve to create it approved" do
      expect(missing(build(:billboard, approved: true, published: false))).to eq(%w[approve])
    end

    it "needs publish to create it published" do
      expect(missing(build(:billboard, approved: false, published: true))).to eq(%w[publish])
    end

    it "needs both to create it live" do
      expect(missing(build(:billboard, approved: true, published: true))).to eq(%w[approve publish])
    end
  end

  describe "changing an unapproved billboard" do
    let(:billboard) { create(:billboard, approved: false, published: false) }

    it "needs nothing to edit its content" do
      billboard.assign_attributes(body_markdown: "New copy", name: "New name", placement_area: "post_comments")

      expect(missing(billboard)).to be_empty
    end

    it "needs approve to approve it" do
      billboard.approved = true

      expect(missing(billboard)).to eq(%w[approve])
    end

    it "needs publish to publish it" do
      billboard.published = true

      expect(missing(billboard)).to eq(%w[publish])
    end

    it "needs nothing to unpublish it" do
      billboard.update_columns(published: true)
      billboard.published = false

      expect(missing(billboard)).to be_empty
    end
  end

  describe "changing an approved billboard" do
    let(:billboard) { create(:billboard, approved: true, published: true) }

    it "needs nothing when nothing changes" do
      billboard.assign_attributes(approved: true, published: true, body_markdown: billboard.body_markdown)

      expect(missing(billboard)).to be_empty
    end

    it "needs nothing to unpublish it" do
      billboard.published = false

      expect(missing(billboard)).to be_empty
    end

    it "needs nothing to unapprove it" do
      billboard.approved = false

      expect(missing(billboard)).to be_empty
    end

    it "needs nothing to unapprove it while editing, since the edit then needs approval again" do
      billboard.assign_attributes(approved: false, body_markdown: "Changed after approval")

      expect(missing(billboard)).to be_empty
    end

    %i[body_markdown name placement_area display_to type_of creator_id organization_id expires_at
       target_geolocations tag_list render_mode template].each do |attribute|
      it "needs modify_approved to change #{attribute}" do
        value = {
          body_markdown: "Changed after approval",
          name: "Changed",
          placement_area: "post_comments",
          display_to: "logged_in",
          type_of: "external",
          creator_id: create(:user).id,
          organization_id: create(:organization).id,
          expires_at: 1.week.from_now,
          target_geolocations: "US-WA",
          tag_list: "ruby",
          render_mode: "raw",
          template: "plain"
        }.fetch(attribute)
        billboard.public_send(:"#{attribute}=", value)

        expect(missing(billboard)).to eq(%w[modify_approved])
      end
    end

    it "needs modify_approved to edit it while unpublishing it" do
      billboard.assign_attributes(published: false, body_markdown: "Changed after approval")

      expect(missing(billboard)).to eq(%w[modify_approved])
    end

    it "needs modify_approved to delete it" do
      expect(missing(billboard, :destroy)).to eq(%w[modify_approved])
    end

    context "when it is approved but unpublished" do
      let(:billboard) { create(:billboard, approved: true, published: false) }

      it "needs publish to publish it" do
        billboard.published = true

        expect(missing(billboard)).to eq(%w[publish])
      end

      it "needs modify_approved to edit it" do
        billboard.body_markdown = "Swapped in after approval"

        expect(missing(billboard)).to eq(%w[modify_approved])
      end
    end
  end

  describe "changing a billboard that belongs to an Event" do
    let(:event) { create(:event) }
    let(:billboard) { create(:billboard, event: event, approved: false, published: true) }

    it "needs modify_approved to edit its content even though it is unapproved" do
      billboard.body_markdown = "Swapped before the broadcast worker approves it"

      expect(missing(billboard)).to eq(%w[modify_approved])
    end

    it "needs modify_approved to edit it while unapproving it, since the worker approves it again" do
      billboard.assign_attributes(approved: false, published: false, body_markdown: "Swapped")

      expect(missing(billboard)).to eq(%w[modify_approved])
    end

    it "needs nothing to unpublish it" do
      billboard.published = false

      expect(missing(billboard)).to be_empty
    end

    it "needs nothing to unapprove it" do
      billboard.update_columns(approved: true)
      billboard.approved = false

      expect(missing(billboard)).to be_empty
    end

    it "needs modify_approved to detach it from its Event" do
      billboard.event_id = nil

      expect(missing(billboard)).to eq(%w[modify_approved])
    end

    it "needs modify_approved to attach a draft to an Event" do
      draft = create(:billboard, approved: false, published: false)
      draft.event_id = event.id

      expect(missing(draft)).to eq(%w[modify_approved])
    end

    it "needs modify_approved to create one" do
      expect(missing(build(:billboard, event: event, approved: false, published: false))).to eq(%w[modify_approved])
    end

    it "needs modify_approved to delete it" do
      expect(missing(billboard, :destroy)).to eq(%w[modify_approved])
    end
  end

  it "needs nothing to delete an unapproved billboard" do
    expect(missing(create(:billboard, approved: false, published: true), :destroy)).to be_empty
  end

  describe "moving a billboard between campaigns" do
    let(:live_campaign) { BillboardCampaign.create!(name: "Live", max_impressions_count: 1_000) }
    let(:quiet_campaign) { BillboardCampaign.create!(name: "Quiet", max_impressions_count: 1_000) }
    let(:draft) { create(:billboard, approved: false, published: false) }

    before do
      create(:billboard, approved: true, published: true, billboard_campaign: live_campaign)
      create(:billboard, approved: false, published: false, billboard_campaign: quiet_campaign)
    end

    it "needs modify_approved to join a campaign with a live billboard" do
      draft.billboard_campaign = live_campaign

      expect(missing(draft)).to eq(%w[modify_approved])
    end

    it "needs modify_approved to leave a campaign with a live billboard" do
      draft.update_column(:billboard_campaign_id, live_campaign.id)
      draft.billboard_campaign = nil

      expect(missing(draft)).to eq(%w[modify_approved])
    end

    it "needs modify_approved for an approved member taken down while leaving" do
      member = create(:billboard, approved: true, published: true, billboard_campaign: live_campaign)
      member.assign_attributes(approved: false, billboard_campaign: nil)

      expect(missing(member)).to eq(%w[modify_approved])
    end

    it "counts an Event-owned sibling as live" do
      create(:billboard, approved: false, event: create(:event), billboard_campaign: quiet_campaign)
      draft.billboard_campaign = quiet_campaign

      expect(missing(draft)).to eq(%w[modify_approved])
    end

    it "needs nothing to move between campaigns with no live billboard" do
      other_quiet = BillboardCampaign.create!(name: "Other quiet")
      draft.update_column(:billboard_campaign_id, quiet_campaign.id)
      draft.billboard_campaign = other_quiet

      expect(missing(draft)).to be_empty
    end

    it "needs modify_approved to delete a member of a campaign with a live billboard" do
      draft.update_column(:billboard_campaign_id, live_campaign.id)

      expect(missing(draft.reload, :destroy)).to eq(%w[modify_approved])
    end

    it "needs nothing to delete a member of a campaign with no live billboard" do
      draft.update_column(:billboard_campaign_id, quiet_campaign.id)

      expect(missing(draft.reload, :destroy)).to be_empty
    end

    context "with modify_approved" do
      let(:allowed) { %w[modify_approved] }

      it "can join a campaign with a live billboard" do
        draft.billboard_campaign = live_campaign

        expect(missing(draft)).to be_empty
      end
    end
  end

  context "when the grant allows every clause" do
    let(:allowed) { SubPermissions.clauses_for("Billboard") }

    it "needs nothing for any change", :aggregate_failures do
      live = create(:billboard, approved: true, published: true)
      live.body_markdown = "Changed"

      expect(missing(build(:billboard, approved: true, published: true))).to be_empty
      expect(missing(live)).to be_empty
      expect(missing(live, :destroy)).to be_empty
    end
  end

  context "when the grant allows only some clauses" do
    let(:allowed) { %w[publish] }

    it "reports only the missing ones" do
      expect(missing(build(:billboard, approved: true, published: true))).to eq(%w[approve])
    end
  end

  it "answers save? and destroy?", :aggregate_failures do
    draft = build(:billboard, approved: false, published: false)
    live = create(:billboard, approved: true, published: true)

    expect(described_class.new(user, draft)).to permit_action(:save)
    expect(described_class.new(user, build(:billboard, approved: true))).not_to permit_action(:save)
    expect(described_class.new(user, live)).not_to permit_action(:destroy)
  end

  it "requires a user" do
    expect { described_class.new(nil, build(:billboard)) }.to raise_error(Pundit::NotAuthorizedError)
  end
end
