require "rails_helper"

RSpec.describe Notifications::CoAuthor::Send, type: :service do
  let(:author)    { create(:user) }
  let(:co_author) { create(:user) }

  def co_authored_article(co_authors: [co_author], published: true)
    create(:article, user: author, published: published, co_author_ids: co_authors.map(&:id))
  end

  def co_author_notifications(article)
    Notification.where(notifiable_id: article.id, notifiable_type: "Article", action: "CoAuthor")
  end

  it "notifies a credited co-author" do
    article = co_authored_article

    expect { described_class.call(article) }
      .to change { co_author_notifications(article).count }.by(1)

    expect(co_author_notifications(article).first.user_id).to eq(co_author.id)
  end

  it "stores the article and author in the payload" do
    article = co_authored_article
    described_class.call(article)

    json_data = co_author_notifications(article).first.json_data

    expect(json_data["article"]["title"]).to eq(article.title)
    expect(json_data["user"]["id"]).to eq(author.id)
  end

  it "does not notify twice when called again" do
    article = co_authored_article
    described_class.call(article)

    expect { described_class.call(article) }
      .not_to change { co_author_notifications(article).count }
  end

  it "only notifies co-authors who do not have a notification yet" do
    second_co_author = create(:user)
    article = co_authored_article
    described_class.call(article)

    article.update_columns(co_author_ids: [co_author.id, second_co_author.id])

    expect { described_class.call(article.reload) }
      .to change { co_author_notifications(article).count }.by(1)

    expect(co_author_notifications(article).pluck(:user_id))
      .to contain_exactly(co_author.id, second_co_author.id)
  end

  it "does not notify the author even if listed as a co-author" do
    article = co_authored_article
    article.update_columns(co_author_ids: [author.id])

    described_class.call(article.reload)

    expect(co_author_notifications(article).pluck(:user_id)).not_to include(author.id)
  end

  it "does nothing for an unpublished article" do
    article = co_authored_article(published: false)

    expect { described_class.call(article) }
      .not_to change { co_author_notifications(article).count }
  end

  it "does nothing when there are no co-authors" do
    article = create(:article, user: author, published: true)

    expect { described_class.call(article) }.not_to change(Notification, :count)
  end
end
