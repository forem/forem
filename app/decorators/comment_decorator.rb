class CommentDecorator < ApplicationDecorator
  delegate_all

  def low_quality
    score < -75
  end

  def long_published_at
    created_at&.strftime("%e %B, %Y at %I:%M%p %Z")
  end
end
