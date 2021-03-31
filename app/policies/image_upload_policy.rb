class ImageUploadPolicy < ApplicationPolicy
  def create?
    !user_suspended?
  end
end
