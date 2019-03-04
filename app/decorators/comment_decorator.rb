class CommentDecorator < ApplicationDecorator
  delegate_all

  LOW_QUALITY_THRESHOLD = -75

  def low_quality
    score < LOW_QUALITY_THRESHOLD
  end
end
