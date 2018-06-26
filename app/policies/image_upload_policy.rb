class ImageUploadPolicy < ApplicationPolicy
  def create?
    !user.banned
  end
end
