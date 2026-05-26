require "rails_helper"

RSpec.describe LinkTag, type: :liquid_tag do
  let(:user) { create(:user, username: "username45", name: "Chase Danger", profile_image: nil) }
  let(:article) do
    create(:article, user_id: user.id, title: "test this please", tags: "html, rss, css")
  end
  let(:org) { create(:organization) }
  let(:org_user) do
    user = create(:user)
    build_stubbed(:organization_membership, user: user, organization: org)
    user
  end
  let(:org_article) do
    create(:article, user_id: org_user.id, title: "test this please", tags: "html, ruby, js",
                     organization_id: org.id)
  end
  let(:escaped_article) do
    create(:article, user_id: user.id, title: "Hello & Hi <3 <script>", tags: "tag")
  end

  def generate_new_liquid(slug:)
    Liquid::Template.register_tag("link", LinkTag)
    Liquid::Template.parse("{% link #{slug} %}")
  end

  def generate_new_liquid_alias(slug:)
    Liquid::Template.register_tag("post", described_class)
    Liquid::Template.parse("{% post #{slug} %}")
  end

  def assert_link_tag_renders(rendered, article)
    expect(rendered).to include("ltag__link--embedded")
    expect(rendered).to include(CGI.escapeHTML(article.title))
    expect(rendered).to include(article.user.username)
  end

  def assert_org_link_tag_renders(rendered, article)
    expect(rendered).to include("ltag__link--embedded")
    expect(rendered).to include(CGI.escapeHTML(article.title))
    expect(rendered).to include(article.user.username)
  end

  it 'can use "post" as an alias' do
    liquid = generate_new_liquid_alias(slug: "/#{user.username}/#{article.slug}")
    assert_link_tag_renders(liquid.render, article)
  end

  it "does not raise an error when invalid" do
    expect { generate_new_liquid(slug: "fake_username/fake_article_slug") }
      .not_to raise_error
  end

  it "renders a proper link tag" do
    liquid = generate_new_liquid(slug: "#{user.username}/#{article.slug}")
    assert_link_tag_renders(liquid.render, article)
  end

  it "also tries to look for article by organization if failed to find by username" do
    liquid = generate_new_liquid(slug: "#{org_article.username}/#{org_article.slug}")
    assert_org_link_tag_renders(liquid.render, org_article)
  end

  it "renders with a leading slash" do
    liquid = generate_new_liquid(slug: "/#{user.username}/#{article.slug}")
    assert_link_tag_renders(liquid.render, article)
  end

  it "renders with a trailing slash" do
    liquid = generate_new_liquid(slug: "#{user.username}/#{article.slug}/")
    assert_link_tag_renders(liquid.render, article)
  end

  it "renders with both leading and trailing slashes" do
    liquid = generate_new_liquid(slug: "/#{user.username}/#{article.slug}/")
    assert_link_tag_renders(liquid.render, article)
  end

  it "renders with a full link" do
    liquid = generate_new_liquid(slug: "https://#{Settings::General.app_domain}/#{user.username}/#{article.slug}")
    assert_link_tag_renders(liquid.render, article)
  end

  it "raise error when url belongs to different domain" do
    expect do
      generate_new_liquid(slug: "https://xkcd.com#{article.path}")
    end.to raise_error(StandardError)
  end

  it "does not raise error if a subforem with domain exists" do
    create(:subforem, domain: "xkcd.com")
    expect do
      generate_new_liquid(slug: "https://Xkcd.com#{article.path}")
    end.not_to raise_error
  end

  it "renders with a full link with a trailing slash" do
    liquid = generate_new_liquid(slug: "https://#{Settings::General.app_domain}/#{user.username}/#{article.slug}/")
    assert_link_tag_renders(liquid.render, article)
  end

  it "renders with missing article" do
    article.delete
    liquid = generate_new_liquid(slug: "https://#{Settings::General.app_domain}/#{user.username}/#{article.slug}/")
    rendered = liquid.render
    expect(rendered).to include("Post not found or has been removed.")
    expect(rendered).to include("crayons-card")
  end

  it "renders with another subforem domain" do
    create(:subforem, domain: "xkcd.com")
    liquid = generate_new_liquid(slug: "https://xkcd.com/#{user.username}/#{article.slug}/")
    assert_link_tag_renders(liquid.render, article)
  end

  it "escapes title" do
    liquid = generate_new_liquid(slug: "/#{user.username}/#{escaped_article.slug}/")
    assert_link_tag_renders(liquid.render, escaped_article)
  end
end
