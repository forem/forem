class CommentDecorator < ApplicationDecorator
  def low_quality
    score < Comment::LOW_QUALITY_THRESHOLD
  end

  def super_low_quality
    score < Comment::HIDE_THRESHOLD
  end

  def published_timestamp
    return "" if created_at.nil?

    created_at.utc.iso8601
  end

  def published_at_int
    created_at.to_i
  end

  def edited_timestamp
    return "" if edited_at.nil?

    edited_at.utc.iso8601
  end

  def readable_publish_date
    if created_at.year == Time.current.year
      I18n.l(created_at, format: :short)
    else
      I18n.l(created_at, format: :short_with_yy)
    end
  end
end
