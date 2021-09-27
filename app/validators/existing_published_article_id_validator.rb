class ExistingPublishedArticleIdValidator < ActiveModel::EachValidator
  DEFAULT_MESSAGE = "must be a valid published Article identifier".freeze

  def validate_each(record, attribute, value)
    return if Article.published.exists?(id: value)

    record.errors.add(attribute, (options[:message] || DEFAULT_MESSAGE))
  end
end
