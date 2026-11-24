require "rails_helper"

RSpec.describe Notifications::SyncEventPresenter, type: :service do
  let(:author) { create(:user, name: "Ben Halpern") }
  let(:article) { create(:article, user: author, title: "Building Forem") }
  let(:actor_data) { Notifications.user_data(author) }

  def present(**attributes)
    described_class.new(build(:notification, organization: nil, **attributes)).to_h
  end

  it "renders a new post with only its kind, actor, text and absolute url" do
    result = present(notifiable: article, action: "Published",
                     json_data: { user: actor_data, article: Notifications.article_data(article) })

    expect(result).to include(
      "kind" => "new_post",
      "actor" => { "id" => author.id, "username" => author.username, "name" => "Ben Halpern",
                   "profile_image_url" => author.profile_image_90 },
      "text" => "Ben Halpern made a new post: Building Forem",
      "url" => URL.url(article.path),
    )
    expect(result.keys).to eq(%w[kind actor text url])
  end

  it "links to the subforem's domain" do
    subforem = create(:subforem, domain: "other.forem.test")
    allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => "other.forem.test" })

    result = present(notifiable: article, action: "Published", subforem_id: subforem.id,
                     json_data: { user: actor_data, article: Notifications.article_data(article) })

    expect(result["url"]).to eq(URL.url(article.path, "other.forem.test"))
  end

  it "renders one generic line for a comment, titled with the commented post" do
    comment = create(:comment, commentable: article)

    result = present(notifiable: comment, action: nil,
                     json_data: { user: Notifications.user_data(comment.user),
                                  comment: Notifications.comment_data(comment) })

    expect(result).to include("kind" => "comment", "url" => URL.url(comment.path),
                              "text" => "#{comment.user.name} commented on \"Building Forem\"")
  end

  it "counts aggregated reactors and names the reacted-to comment" do
    siblings = Array.new(4) { { category: "like", user: actor_data } }
    json_data = {
      user: actor_data,
      reaction: { reactable_type: "Comment", reactable: { path: "/ben/comment/1", title: "Nice post" },
                  aggregated_siblings: siblings }
    }

    result = present(notifiable: article, action: "Reaction", json_data: json_data)

    expect(result).to include("kind" => "reaction", "url" => URL.url("/ben/comment/1"),
                              "text" => "Ben Halpern and 3 others reacted to your comment \"Nice post\"")
  end

  it "renders a single follower without an others clause" do
    follow = author.follow(create(:user))

    result = present(notifiable: follow, action: "Follow",
                     json_data: { user: actor_data, aggregated_siblings: [actor_data] })

    expect(result).to include("kind" => "follow", "text" => "Ben Halpern followed you",
                              "url" => URL.url(author.path))
  end

  it "maps the community favorite path the CORE-1533 audit missed" do
    result = present(notifiable: article, action: "Favorited",
                     json_data: { user: actor_data, article: Notifications.article_data(article) })

    expect(result).to include("kind" => "community_favorite",
                              "text" => "Ben Halpern picked \"Building Forem\" as a community favorite")
  end

  it "renders milestones without an actor" do
    result = present(notifiable: article, action: "Milestone::View::1024",
                     json_data: { article: Notifications.article_data(article) })

    expect(result).to include("kind" => "milestone", "actor" => nil,
                              "text" => "Your post \"Building Forem\" passed 1024 views")
  end

  it "renders badges without an actor, since the badge's user is the recipient" do
    result = present(notifiable: article, notifiable_type: "BadgeAchievement", action: nil,
                     json_data: { user: actor_data, badge_achievement: { badge: { title: "Writing Debut" } } })

    expect(result).to include("kind" => "badge", "actor" => nil, "text" => "You earned the Writing Debut badge",
                              "url" => URL.url(author.path))
  end

  it "renders an organization invitation without an inviter" do
    organization = create(:organization, name: "Forem Systems")
    membership = create(:organization_membership, organization: organization, type_of_user: "pending")

    result = present(notifiable: membership, action: "Invited",
                     json_data: { organization: Notifications.organization_data(organization) })

    expect(result).to include(
      "kind" => "org_invitation",
      "actor" => nil,
      "text" => "You were invited to join Forem Systems",
    )
  end

  it "renders an admin notification from its own title and link" do
    json_data = { admin_notification: { title: "You're in", url: "https://mlh.io/x" } }
    notification = create(:notification, user: create(:user), organization: nil,
                                         notifiable: create(:admin_notification), action: nil, json_data: json_data)

    expect(described_class.new(notification).to_h).to include(
      "kind" => "admin", "actor" => nil, "text" => "You're in", "url" => "https://mlh.io/x",
    )
  end

  it "falls back to other for kinds it does not know" do
    result = present(notifiable: article, action: "SomethingNew", json_data: {})

    expect(result).to include("kind" => "other", "text" => "You have a new notification",
                              "url" => URL.url("/notifications"))
  end

  it "caps the text length" do
    article.update_columns(title: "a" * 400)
    long_name_actor = actor_data.merge(name: "b" * 90)

    result = present(notifiable: article, action: "Published",
                     json_data: { user: long_name_actor, article: Notifications.article_data(article) })

    expect(result["text"].length).to eq(described_class::TEXT_LIMIT)
  end
end
