require "rails_helper"

RSpec.describe Notifications::CoAuthor::Remove, type: :service do
  let(:author)    { create(:user) }
  let(:co_author) { create(:user) }
  let(:article)   { create(:article, user: author, published: true, co_author_ids: [co_author.id]) }

  def co_author_notifications
    Notification.where(notifiable_id: article.id, notifiable_type: "Article", action: "CoAuthor")
  end

  before { Notifications::CoAuthor::Send.call(article) }

  it "removes the notification for a dropped co-author" do
    expect { described_class.call(article.id, [co_author.id]) }
      .to change(co_author_notifications, :count).by(-1)
  end

  it "leaves notifications for co-authors who remain" do
    other = create(:user)

    expect { described_class.call(article.id, [other.id]) }
      .not_to change(co_author_notifications, :count)
  end

  it "does nothing when given no user ids" do
    expect { described_class.call(article.id, []) }
      .not_to change(co_author_notifications, :count)
  end
end
