module TagListValidateable
  extend ActiveSupport::Concern
  # we check tags names aren't too long and don't contain non alphabet characters
  def validate_tag_name(tag_list)
    tag_list.each do |tag|
      new_tag = Tag.new(name: tag)
      new_tag.validate_name
      new_tag.errors.messages[:name].each { |message| errors.add(:tag, "\"#{tag}\" #{message}") }
    end
  end
end
