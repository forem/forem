require "rails_helper"

RSpec.describe OrgTeamTag, type: :liquid_tag do
  let(:organization) { create(:organization) }
  let(:liquid_tag_options) { { source: organization, user: nil } }

  def parse_tag(input, options = liquid_tag_options)
    Liquid::Template.parse("{% org_team #{input} %}", options)
  end

  def rendered_user_pics(rendered)
    rendered.scan("org-sidebar-widget-user-pic").size
  end

  before do
    Liquid::Template.register_tag("org_team", described_class)
  end

  context "when given a valid organization slug" do
    it "renders team members" do
      member = create(:user)
      create(:organization_membership, organization: organization, user: member, type_of_user: "member")
      liquid = parse_tag(organization.slug)
      rendered = liquid.render
      expect(rendered).to include(member.username)
    end

    it "renders without error when no members exist" do
      liquid = parse_tag(organization.slug)
      rendered = liquid.render
      expect(rendered).to include("ltag-org-team")
    end
  end

  context "when given an invalid slug" do
    it "raises an error" do
      expect do
        parse_tag("nonexistent-org-slug")
      end.to raise_error(StandardError, /Invalid organization slug/)
    end
  end

  context "when used outside Organization context" do
    let(:article_source) { create(:article) }

    it "raises an InvalidParseContext error" do
      expect do
        parse_tag(organization.slug, { source: article_source, user: nil })
      end.to raise_error(LiquidTags::Errors::InvalidParseContext)
    end
  end

  describe "limit option" do
    it "limits the number of members returned" do
      5.times do
        user = create(:user)
        create(:organization_membership, organization: organization, user: user, type_of_user: "member")
      end
      liquid = parse_tag("#{organization.slug} limit=3")
      rendered = liquid.render
      expect(rendered_user_pics(rendered)).to eq(3)
    end

    it "defaults to 50 members" do
      2.times do
        user = create(:user)
        create(:organization_membership, organization: organization, user: user, type_of_user: "member")
      end
      liquid = parse_tag(organization.slug)
      rendered = liquid.render
      expect(rendered_user_pics(rendered)).to eq(2)
    end

    it "raises an error for limit above 50" do
      expect do
        parse_tag("#{organization.slug} limit=51")
      end.to raise_error(StandardError, /Limit must be between 1 and 50/)
    end

    it "raises an error for limit of 0" do
      expect do
        parse_tag("#{organization.slug} limit=0")
      end.to raise_error(StandardError, /Limit must be between 1 and 50/)
    end

    it "raises an error for non-integer limit" do
      expect do
        parse_tag("#{organization.slug} limit=abc")
      end.to raise_error(StandardError, /Limit must be between 1 and 50/)
    end
  end

  describe "role option" do
    let!(:admin_user) do
      user = create(:user)
      create(:organization_membership, organization: organization, user: user, type_of_user: "admin")
      user
    end
    let!(:member_user) do
      user = create(:user)
      create(:organization_membership, organization: organization, user: user, type_of_user: "member")
      user
    end
    let!(:guest_user) do
      user = create(:user)
      create(:organization_membership, organization: organization, user: user, type_of_user: "guest")
      user
    end

    it "shows only admins with role=admins" do
      liquid = parse_tag("#{organization.slug} role=admins")
      rendered = liquid.render
      expect(rendered).to include(admin_user.username)
      expect(rendered).not_to include(member_user.username)
      expect(rendered).not_to include(guest_user.username)
    end

    it "shows only members (non-admin, non-guest) with role=members" do
      liquid = parse_tag("#{organization.slug} role=members")
      rendered = liquid.render
      expect(rendered).to include(member_user.username)
      expect(rendered).not_to include(admin_user.username)
      expect(rendered).not_to include(guest_user.username)
    end

    it "shows all active users with role=all" do
      liquid = parse_tag("#{organization.slug} role=all")
      rendered = liquid.render
      expect(rendered).to include(admin_user.username)
      expect(rendered).to include(member_user.username)
      expect(rendered).to include(guest_user.username)
    end

    it "defaults to all active users" do
      liquid = parse_tag(organization.slug)
      rendered = liquid.render
      expect(rendered).to include(admin_user.username)
      expect(rendered).to include(member_user.username)
      expect(rendered).to include(guest_user.username)
    end

    it "raises an error for invalid role value" do
      expect do
        parse_tag("#{organization.slug} role=invalid")
      end.to raise_error(StandardError, /Role must be one of/)
    end
  end

  describe "combined options" do
    it "applies role and limit together" do
      3.times do
        user = create(:user)
        create(:organization_membership, organization: organization, user: user, type_of_user: "admin")
      end
      user = create(:user)
      create(:organization_membership, organization: organization, user: user, type_of_user: "member")

      liquid = parse_tag("#{organization.slug} role=admins limit=2")
      rendered = liquid.render
      expect(rendered_user_pics(rendered)).to eq(2)
      expect(rendered).not_to include(user.username)
    end
  end

  describe "invalid options" do
    it "raises an error for unknown option key" do
      expect do
        parse_tag("#{organization.slug} foo=bar")
      end.to raise_error(StandardError, /Invalid option 'foo'/)
    end

    it "raises an error for malformed option" do
      expect do
        parse_tag("#{organization.slug} notanoption")
      end.to raise_error(StandardError, /Invalid option/)
    end
  end
end
