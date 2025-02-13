class NotificationDecorator < ApplicationDecorator
  extend ActiveModel::Naming

  NOTIFIABLE_STUB = Struct.new(:name, :id) do
    def class
      Struct.new(:name).new(name)
    end

    # @see ApplicationRecord#class_name
    alias_method :class_name, :name
  end.freeze

  # returns a stub notifiable object with name and id
  def mocked_object(type)
    return NOTIFIABLE_STUB.new("", nil) if json_data.blank?

    NOTIFIABLE_STUB.new(json_data[type]["class"]["name"], json_data[type]["id"])
  end

  # returns the type of a milestone notification action,
  # eg. "Milestone::Reaction::64"
  def milestone_type
    return "" if action.blank?

    action.split("::").second
  end

  # returns the count of a milestone notification action,
  # eg. "Milestone::Reaction::64"
  def milestone_count
    return "" if action.blank?

    action.split("::").third
  end

  def siblings
    @siblings ||= begin
      aggregated_data = json_data.dig("reaction", "aggregated_siblings")
      aggregated_data ||= []
      aggregated_data.select { |n| n["created_at"] > 24.hours.ago }
    end
  end

  def to_model
    self
  end

  def subscription_for(user)
    subscription_to_comment_ancestry_for(user) ||
      subscription_to_comment_for(user) ||
      subscription_to_commentable_article_for(user) ||
      subscription_to_article_for(user)
  end

  def subscription_to_article_for(user)
    return unless article_id

    subscription_to_notifiable_for(user,
                                   notifiable_type: "Article",
                                   notifiable_id: article_id)
  end

  def subscription_to_comment_for(user)
    return unless comment_ancestry

    subscription_to_notifiable_for(user,
                                   notifiable_type: "Comment",
                                   notifiable_id: comment_id)
  end

  def subscription_to_comment_ancestry_for(user)
    return unless comment_ancestry

    subscription_to_notifiable_for(user,
                                   notifiable_type: "Comment",
                                   notifiable_id: comment_ancestry.split("/"))
  end

  def subscription_to_commentable_article_for(user)
    return unless commentable_article_id

    subscription_to_notifiable_for(user,
                                   notifiable_type: "Article",
                                   notifiable_id: commentable_article_id)
  end

  def subscription_to_notifiable_for(user, **notifiable)
    user.notification_subscriptions.for_notifiable(**notifiable).first
  end

  # In many cases, we render a partial specific to a notification's notifiable_type
  # (Milestone, Article, Comment, etc.) However, reacting-to-an-article or
  # reacting-to-a-comment will have a misleading "Article" or "Comment" notifiable_type
  # (respectively), so a "reaction-type notification" is somewhat more involved. We also have
  # distinct partials for aggregate reactions ("Username and several others reacted to...")
  # and individual reactions.
  def to_partial_path
    return "notifications/#{notifiable_type.downcase}" unless reaction?

    if siblings.any?
      "notifications/aggregated_reactions"
    else
      "notifications/single_reaction"
    end
  end

  def actors
    @actors ||= siblings.pluck("user").uniq
  end

  def milestone?
    type_inquirer.milestone? || (type_inquirer.article? && action.include?("Milestone"))
  end

  def multiple_reactors?
    actors.size > 1
  end

  def reaction?
    type_inquirer.reaction? ||
      (type_inquirer.article? && action_inquirer.reaction?) ||
      (type_inquirer.comment? && action_inquirer.reaction?)
  end

  def any_cached_reactions_for_object?(user, object_type = "article", category: "like")
    Reaction.cached_any_reactions_for?(mocked_object(object_type), user, category)
  end

  def article_id
    @article_id ||= json_data.dig "article", "id"
  end

  def article_url
    @article_url ||= json_data.dig("article", "url") || json_data.dig("article", "path")
  end

  def article_title
    @article_title ||= json_data.dig "article", "title"
  end

  def article_tag_list
    @article_tag_list ||= (json_data.dig "article", "cached_tag_list_array") || []
  end

  def article_updated_at
    @article_updated_at ||= json_data.dig "article", "updated_at"
  end

  def comment_ancestry
    @comment_ancestry ||= json_data.dig "comment", "ancestry"
  end

  def comment_id
    @comment_id ||= json_data.dig "comment", "id"
  end

  def comment_last_ancestor
    @comment_last_ancestor ||= (json_data.dig("comment", "ancestors") || []).last || {}
  end

  def comment_path
    @comment_path ||= json_data.dig "comment", "path"
  end

  def comment_depth
    @comment_depth ||= json_data.dig("comment", "depth") || -1
  end

  def comment_processed_html
    @comment_processed_html ||= json_data.dig "comment", "processed_html"
  end

  def comment_updated_at
    @comment_updated_at ||= json_data.dig "comment", "updated_at"
  end

  def commentable
    @commentable ||= json_data.dig "comment", "commentable"
  end

  def commentable_id
    @commentable_id ||= json_data.dig "comment", "commentable", "id"
  end

  def commentable_article_id
    @commentable_article_id ||= begin
      commentable = json_data.dig "comment", "commentable"
      commentable["id"] if commentable&.dig("class", "name") == "Article"
    end
  end

  def commentable_class_name
    @commentable_class_name ||= json_data.dig "comment", "commentable", "class", "name"
  end

  # TODO: This is an odd one - contrast with reactable_type?
  def reactable_class
    @reactable_class ||= json_data.dig "reaction", "reactable", "class", "name"
  end

  def reactable_path
    @reactable_path ||= json_data.dig "reaction", "reactable", "path"
  end

  def reactable_title
    @reactable_title ||= json_data.dig "reaction", "reactable", "title"
  end

  def reactable_type
    @reactable_type ||= json_data.dig "reaction", "reactable", "type"
  end

  def reaction_category
    @reaction_category ||= json_data.dig "reaction", "category"
  end

  # NOTE: this is *siblings* not json_data, breaking a pattern above
  def reaction_categories
    @reaction_categories ||= siblings.pluck("category")
  end

  # NOTE: Using *siblings*, not json_data, via reaction_categories
  def unique_reaction_categories
    @unique_reaction_categories ||= reaction_categories.uniq
  end

  def user_id
    @user_id ||= json_data.dig "user", "id"
  end

  def user_name
    @user_name ||= json_data.dig "user", "name"
  end

  def user_path
    @user_path ||= json_data.dig "user", "path"
  end

  def user_profile_image_90
    @user_profile_image_90 ||= json_data.dig "user", "profile_image_90"
  end

  private

  def action_inquirer
    @action_inquirer ||= ActiveSupport::StringInquirer.new(action&.downcase || "")
  end

  def type_inquirer
    @type_inquirer ||= ActiveSupport::StringInquirer.new(notifiable_type&.downcase || "")
  end

  def json_data
    read_attribute(:json_data) || {}
  end
end
