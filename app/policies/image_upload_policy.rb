class ImageUploadPolicy < ApplicationPolicy
  def create?
    !user_is_banned?
  end
end
