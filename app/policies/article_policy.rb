class ArticlePolicy < ApplicationPolicy
  def update?
    user_is_author? || user_is_admin? || user_is_org_admin?
  end

  def new?
    true
  end

  def create?
    !user_is_banned?
  end

  def delete_confirm?
    update?
  end

  def destroy?
    update?
  end

  def preview?
    true
  end

  def permitted_attributes
    %i[title body_html body_markdown user_id main_image published
       description allow_small_edits allow_big_edits tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url]
  end

  private

  def user_is_author?
    record.user_id == user.id
  end

  def user_is_org_admin?
    user.org_admin && user.organization_id == record.organization_id
  end

  def user_is_banned?
    user.has_role?(:banned)
  end
end
