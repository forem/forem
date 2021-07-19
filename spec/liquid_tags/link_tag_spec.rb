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

  def correct_link_html(article)
    tags = article.tag_list.map { |t| "<span class='ltag__link__tag'>##{t}</span>" }.join("\n#{"\s" * 8}")
    <<~HTML
      <div class='ltag__link'>
        <a href='#{article.user.path}' class='ltag__link__link'>
          <div class='ltag__link__pic'>
            <img src='#{Images::Profile.call(article.user.profile_image_url, length: 150)}' alt='#{article.user.username}'>
          </div>
        </a>
        <a href='#{article.path}' class='ltag__link__link'>
          <div class='ltag__link__content'>
            <h2>#{CGI.escapeHTML(article.title)}</h2>
            <h3>#{CGI.escapeHTML(article.user.name)} ・ #{article.readable_publish_date} ・ #{article.reading_time} min read</h3>
            <div class='ltag__link__taglist'>
              #{tags}
            </div>
          </div>
        </a>
      </div>
    HTML
  end

  def correct_org_link_html(article)
    tags = article.tag_list.map { |t| "<span class='ltag__link__tag'>##{t}</span>" }.join("\n#{"\s" * 8}")

    <<~HTML
      <div class='ltag__link'>
        <a href='#{article.organization.path}' class='ltag__link__link'>
          <div class='ltag__link__org__pic'>
            <img src='#{Images::Profile.call(article.organization.profile_image_url, length: 150)}' alt='#{CGI.escapeHTML(article.organization.name)}'>
            <div class='ltag__link__user__pic'>
              <img src='#{Images::Profile.call(article.user.profile_image_url, length: 150)}' alt=''>
            </div>
          </div>
        </a>
        <a href='#{article.path}' class='ltag__link__link'>
          <div class='ltag__link__content'>
            <h2>#{CGI.escapeHTML(article.title)}</h2>
            <h3>#{CGI.escapeHTML(article.user.name)} for #{CGI.escapeHTML(article.organization.name)} ・ #{article.readable_publish_date} ・ #{article.reading_time} min read</h3>
            <div class='ltag__link__taglist'>
              #{tags}
            </div>
          </div>
        </a>
      </div>
    HTML
  end

  def missing_article_html
    <<~HTML
      <div class='ltag__link'>
        <div class='ltag__link__content'>
          <div class='missing'>
            <h2>Article No Longer Available</h2>
          </div>
        </div>
      </div>
    HTML
  end

  it 'can use "post" as an alias' do
    liquid = generate_new_liquid_alias(slug: "/#{user.username}/#{article.slug}")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "does not raise an error when invalid" do
    expect { generate_new_liquid(slug: "fake_username/fake_article_slug") }
      .not_to raise_error
  end

  it "renders a proper link tag" do
    liquid = generate_new_liquid(slug: "#{user.username}/#{article.slug}")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "also tries to look for article by organization if failed to find by username" do
    liquid = generate_new_liquid(slug: "#{org_article.username}/#{org_article.slug}")
    expect(liquid.render).to eq(correct_org_link_html(org_article))
  end

  it "renders with a leading slash" do
    liquid = generate_new_liquid(slug: "/#{user.username}/#{article.slug}")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "renders with a trailing slash" do
    liquid = generate_new_liquid(slug: "#{user.username}/#{article.slug}/")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "renders with both leading and trailing slashes" do
    liquid = generate_new_liquid(slug: "/#{user.username}/#{article.slug}/")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "renders with a full link" do
    liquid = generate_new_liquid(slug: "https://#{Settings::General.app_domain}/#{user.username}/#{article.slug}")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "raise error when url belongs to different domain" do
    expect do
      generate_new_liquid(slug: "https://xkcd.com/2363/")
    end.to raise_error(StandardError)
  end

  it "renders default reading time of 1 minute for short articles" do
    liquid = generate_new_liquid(slug: "/#{user.username}/#{article.slug}/")
    expect(liquid.render).to include("1 min read")
  end

  it "renders reading time of article lengthy articles" do
    template = file_fixture("article_long_content.txt").read
    article = create(:article, user: user, body_markdown: template)
    liquid = generate_new_liquid(slug: "/#{user.username}/#{article.slug}/")
    expect(liquid.render).to include("3 min read")
  end

  it "renders with a full link with a trailing slash" do
    liquid = generate_new_liquid(slug: "https://#{Settings::General.app_domain}/#{user.username}/#{article.slug}/")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "renders with missing article" do
    article.delete
    liquid = generate_new_liquid(slug: "https://#{Settings::General.app_domain}/#{user.username}/#{article.slug}/")
    expect(liquid.render).to eq(missing_article_html)
  end

  it "escapes title" do
    liquid = generate_new_liquid(slug: "/#{user.username}/#{escaped_article.slug}/")
    expect(liquid.render).to eq(correct_link_html(escaped_article))
  end
end
