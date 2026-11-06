require "rails_helper"

RSpec.describe "users/_sidebar" do
  let(:user) { create(:user) }

  before do
    assign(:user, user)
    assign(:profile, user.profile.decorate)
  end

  it "renders member and admin organizations with only the sidebar columns" do
    memberships = %w[member admin guest pending].map do |type|
      create(:organization_membership, user: user, type_of_user: type)
    end
    organizations = memberships.first(2).map(&:organization)
    organizations.last.update_column(:profile_image, nil)
    organizations.last.reload
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('FROM "organizations"') }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      render partial: "users/sidebar", locals: { repositories: [] }
    end

    organizations.each do |organization|
      expect(rendered).to have_link(organization.name, href: "/#{organization.slug}")
      expect(rendered).to have_css("img[src='#{organization.profile_image_url_for(length: 90)}']")
    end
    memberships.last(2).each do |membership|
      expect(rendered).to have_no_link(membership.organization.name)
    end
    expect(queries.size).to eq(1)
    expect(queries.first).to include('SELECT "organizations"."id", "organizations"."name", ' \
                                     '"organizations"."slug", "organizations"."profile_image"')
  end

  it "omits the organization list when there are no memberships" do
    render partial: "users/sidebar", locals: { repositories: [] }

    expect(rendered).to have_no_css(".spec-org-titles")
  end
end
