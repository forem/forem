class ArticleShowPresenter < SimpleDelegator
  def initialize(article, variant_version:, user_signed_in:)
    __setobj__(article)
    @variant_version = variant_version
    @user_signed_in = user_signed_in
  end

  def variant_number
    @variant_version || (@user_signed_in ? 0 : rand(2)) # output_calculation
  end

  def organization
    organization if organization_id.present?
  end

  def comments_count
    cached_tag_list_array.include?("discuss") ? 50 : 30
  end

  def second_user
    User.find(second_user_id) if second_user_id.present?
  end

  def third_user
    User.find(third_user_id) if third_user_id.present?
  end

  def comment
    Comment.new(body_markdown: __getobj__&.comment_template)
  end
end
