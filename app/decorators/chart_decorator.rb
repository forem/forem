class ChartDecorator < Draper::CollectionDecorator
  def total_by_type_per_day(options)
    case options[:type]
    when "Comment"
      object.group_by { |e| e.created_at.beginning_of_day }.transform_values do |v|
        v.select { |comment| comment.commentable_id == options[:article_id] }.length
      end.values # will be an array of integers: [1,2,3,4]
    when "Reaction"
      object.group_by { |e| e.created_at.beginning_of_day }.transform_values do |v|
        v.select { |reaction| reaction.category == options[:category] }.length
      end.values # will be an array of integers: [1,2,3,4]
    end
  end

  def total_per_day
    object.group_by { |e| e.created_at.beginning_of_day }.transform_values(&:length).values
  end

  def formatted_dates
    object.sort_by(&:created_at).group_by { |e| e.created_at.beginning_of_day }.
      transform_keys { |k| k.strftime("%a, %m/%d") }.keys
  end
end
