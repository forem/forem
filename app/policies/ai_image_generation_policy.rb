class AiImageGenerationPolicy < ApplicationPolicy
  def create?
    # All users can generate AI images (as long as they're not spam)
    !user.spam
  end
end

