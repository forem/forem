require "rails_helper"

RSpec.describe SeriesTag, type: :liquid_template do
  let(:user) { create(:user, username: "username45", name: "Chase Danger", profile_image: nil) }
  let(:collection) { create(:collection, slug: "test series", user: user) }
  let(:article) do
    create(:article, user_id: user.id, title: "test this please", tags: "tag1 tag2 tag3", collection_id: collection.id, published: true)
  end
  let(:article2) do
    create(:article, user_id: user.id, title: "test this again", tags: "tag1 tag2 tag3", collection_id: collection.id, published: true)
  end
  let(:org) { create(:organization) }
  let(:org_collection) { create(:collection, slug: "org test series", organization: org) }
  let(:org_user) { create(:user, organization_id: org.id) }
  let(:org_article) do
    create(:article, user_id: org_user.id, title: "test this please", tags: "tag1 tag2 tag3",
                     organization_id: org.id, collection_id: org_collection.id, published: true)
  end
  let(:org_article2) do
    create(:article, user_id: org_user.id, title: "test this again", tags: "tag1 tag2 tag3",
                     organization_id: org.id, collection_id: org_collection.id, published: true)
  end

  def correct_series_html(collection)
    return "" unless collection.articles.published.size > 1

    articles = collection.articles.published.order("published_at ASC").each_with_index do |article, i|
      <<~HTML
        <a href="#{article.path}" class="" title="Published #{article.readable_publish_date}">
        	#{i + 1}) #{article.title}
        </a>
      HTML
    end.join
    <<~HTML
      <div class="article-collection-wrapper">
          <p>#{collection.slug} (#{collection.articles.published.size} Part Series)</p>
      	<div class="article-collection">
      		#{articles}
      	</div>
      </div>
    HTML
  end

  def generate_new_liquid(slug)
    Liquid::Template.register_tag("series", SeriesTag)
    Liquid::Template.parse("{% series #{slug.tr(' ', '-')} %}")
  end

  it "raises an error when invalid" do
    expect { generate_new_liquid("fake_username/fake_article_slug") }.
      to raise_error("Invalid series slug or series does not exist")
  end

  it "renders when valid username and slug are given" do
    liquid = generate_new_liquid("#{user.username}/#{collection.slug}")
    expect { liquid.render }.not_to raise_error
  end

  it "also tries to look for collection by organization if failed to find by username" do
    liquid = generate_new_liquid("#{org.slug}/#{org_collection.slug}")
    expect { liquid.render }.not_to raise_error
  end

  it "renders with a leading slash" do
    liquid = generate_new_liquid("/#{user.username}/#{collection.slug}")
    expect { liquid.render }.not_to raise_error
  end

  it "renders with a trailing slash" do
    liquid = generate_new_liquid("#{user.username}/#{collection.slug}/")
    expect { liquid.render }.not_to raise_error
  end

  it "renders with both leading and trailing slash" do
    liquid = generate_new_liquid("/#{user.username}/#{collection.slug}/")
    expect { liquid.render }.not_to raise_error
  end

  it "renders a proper series tag" do
    liquid = generate_new_liquid("#{user.username}/#{collection.slug}")
    expect(liquid.render).to eq(correct_series_html(collection))
  end
end
