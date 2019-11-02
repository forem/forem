class CommentDecorator < ApplicationDecorator
  delegate_all

  LOW_QUALITY_THRESHOLD = -75

  def low_quality
    score < LOW_QUALITY_THRESHOLD
  end

  def published_timestamp
    return "" if created_at.nil?

    created_at.utc.iso8601
  end

  def edited_timestamp
    return "" if edited_at.nil?

    edited_at.utc.iso8601
  end

  def display_edited?
    edited_at && (edited_at - created_at) > 3.minutes
  end
end
