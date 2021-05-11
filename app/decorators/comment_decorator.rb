class CommentDecorator < ApplicationDecorator
  LOW_QUALITY_THRESHOLD = -75

  def low_quality
    score < LOW_QUALITY_THRESHOLD
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
      created_at.strftime("%b %-e")
    else
      created_at.strftime("%b %-e '%y")
    end
  end
end
