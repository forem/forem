class ExistingPublishedArticleIdValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if Article.published.exists?(id: value)

    record.errors.add(attribute,
                      (options[:message] || I18n.t("validators.existing_published_article_id_validator.default")))
  end
end
