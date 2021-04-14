class UrlValidator < ActiveModel::EachValidator
  VALID_URL = %r{\A(http|https)://([/|.\w\s-])*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\z}.freeze
  URL_MESSAGE = "must be a valid URL".freeze

  def validate_each(record, attribute, value)
    return if value.match?(VALID_URL)

    record.errors.add(attribute, options[:message] || DEFAULT_MESSAGE)
  end
end
