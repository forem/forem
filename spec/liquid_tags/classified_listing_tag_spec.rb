require "rails_helper"

RSpec.describe ClassifiedListingTag, type: :liquid_tag do
  let(:user) { create(:user, username: "dariamorgendorffer", name: "Daria Morgendorffer") }
  let(:user_listing) do
    create(
      :classified_listing,
      user_id: user.id,
      title: "save me pls",
      body_markdown: "sigh sigh sigh",
      processed_html: "<p>sigh sigh sigh</p>",
      category: "cfp",
      tag_list: %w[a b c],
      organization_id: nil,
    )
  end
  let(:expired_listing) do
    datetime = 40.days.ago
    create(
      :classified_listing,
      user_id: user.id,
      title: "this old af",
      body_markdown: "exxpired",
      processed_html: "<p>exxpired</p>",
      category: "cfp",
      tag_list: %w[x y z],
      organization_id: nil,
      bumped_at: datetime,
      created_at: datetime,
      updated_at: datetime,
    )
  end
  let(:org) { create(:organization) }
  let(:org_user) do
    user = create(:user)
    create(:organization_membership, user: user, organization: org)
    user
  end
  let(:org_listing) do
    create(
      :classified_listing,
      user_id: org_user.id,
      title: "this is a job posting",
      body_markdown: "wow code lots get not only money but satisfaction from work",
      processed_html: "<p>wow code lots get not only money but satisfaction from work</p>",
      category: "misc",
      tag_list: %w[a b c],
      organization_id: org.id,
    )
  end

  def generate_new_liquid(slug)
    Liquid::Template.register_tag("listing", ClassifiedListingTag)
    Liquid::Template.parse("{% listing #{slug} %}")
  end

  def correct_link_html(listing)
    tags = ""
    listing.tag_list.each do |tag|
      tags += "<span class='ltag__listing-tag'><a href='/listings?t=#{tag}'>#{tag}</a></span>\n      "
    end
    tags = tags.rstrip
    <<~HTML
      <div class="ltag__listing">
        <div class="ltag__listing-content">
          <h3>
            <a href="/listings/#{listing.category}/#{listing.slug}">
              #{CGI.escapeHTML(listing.title)}
            </a>
          </h3>
          <div class="ltag__listing-body">
            <a href="/listings/#{listing.category}/#{listing.slug}">
              #{listing.processed_html}
            </a>
          </div>
          <div class="ltag__listing-tags">
            #{tags}
          </div>
          <div class="ltag__listing-author-info">
            <a href="/listings/#{listing.category}">#{listing.category}</a>
            ・
            <a href="/#{listing.author.username}">#{listing.author.name}</a>
          </div>
        </div>
      </div>
    HTML
  end

  def render_expired_listing
    <<~HTML
      <div class="ltag__listing">
        <div class="ltag__listing-content">
          <h3>
            <a href="/listings">
              This listing has expired.
            </a>
          </h3>
        </div>
      </div>
    HTML
  end

  it "raises an error when invalid" do
    expect { generate_new_liquid("/listings/fakecategory/fakeslug") }.
      to raise_error("Invalid URL or slug. Listing not found.")
  end

  it "displays expired message when listing is expired" do
    liquid = generate_new_liquid("#{expired_listing.category}/#{expired_listing.slug}")
    expect(liquid.render).to eq(render_expired_listing)
  end

  it "renders a proper listing tag from user listing" do
    liquid = generate_new_liquid("#{user_listing.category}/#{user_listing.slug}")
    expect(liquid.render).to eq(correct_link_html(user_listing))
  end

  it "renders a proper listing tag from org listing" do
    liquid = generate_new_liquid("#{org_listing.category}/#{org_listing.slug}")
    expect(CGI.unescapeHTML(liquid.render)).to eq(correct_link_html(org_listing))
  end
end
