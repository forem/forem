class ImageUploadPolicy < ApplicationPolicy
  def create?
    !user.spam_or_suspended?
  end
end
