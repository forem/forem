module Notifications
  def self.user_data(user)
    {
      id: user.id,
      class: { name: "User" },
      name: user.name,
      username: user.username,
      path: user.path,
      profile_image_90: user.profile_image_90,
      comments_count: user.comments_count,
      created_at: user.created_at
    }
  end

  def self.comment_data(comment)
    {
      id: comment.id,
      class: { name: "Comment" },
      path: comment.path,
      processed_html: comment.processed_html,
      created_at: comment.created_at,
      updated_at: comment.updated_at,
      ancestry: comment.ancestry,
      depth: comment.depth,
      ancestors: ancestor_data(comment),
      commentable: {
        id: comment.commentable.id,
        title: comment.commentable.title,
        path: comment.commentable.path,
        class: {
          name: comment.commentable.class.name
        }
      }
    }
  end

  def self.article_data(article)
    {
      id: article.id,
      cached_tag_list_array: article.decorate.cached_tag_list_array,
      class: { name: "Article" },
      title: article.title,
      path: article.path,
      url: article.url,
      updated_at: article.updated_at,
      published_at: article.published_at,
      readable_publish_date: article.readable_publish_date,
      reading_time: article.reading_time
    }
  end

  def self.organization_data(organization)
    {
      id: organization.id,
      class: { name: "Organization" },
      name: organization.name,
      slug: organization.slug,
      path: organization.path,
      profile_image_90: organization.profile_image_90
    }
  end

  def self.ancestor_data(comment)
    comment.ancestors.includes(:user).map do |ancestor|
      {
        id: ancestor.id,
        title: ancestor.title,
        path: ancestor.path,
        ancestry: ancestor.ancestry,
        depth: ancestor.depth,
        user: {
          username: ancestor.user.username,
          name: ancestor.user.name
        }
      }
    end
  end
  private_class_method :ancestor_data
end
