class CommentDecorator < ApplicationDecorator
  delegate_all

  def low_quality
    score < -75
  end
end
