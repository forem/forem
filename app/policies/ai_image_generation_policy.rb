class AiImageGenerationPolicy < ApplicationPolicy
  def create?
    # Only admins can generate AI images
    user.any_admin?
  end
end

