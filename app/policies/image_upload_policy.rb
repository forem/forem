class ImageUploadPolicy < ApplicationPolicy
  def create?
    !user_is_suspended?
  end
end
