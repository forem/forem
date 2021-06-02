class ExistingArticleIdValidator < ActiveModel::EachValidator
  DEFAULT_MESSAGE = "must be a valid Article identifier".freeze

  def validate_each(record, attribute, value)
    return if Article.exists?(id: value)

    record.errors.add(attribute, (options[:message] || DEFAULT_MESSAGE))
  end
end
