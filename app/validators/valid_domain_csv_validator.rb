class ValidDomainCsvValidator < ActiveModel::EachValidator
  DEFAULT_MESSAGE = "must be a comma-separated list of valid domains".freeze
  VALID_DOMAIN = /^[a-zA-Z0-9]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$/

  def validate_each(record, attribute, value)
    return unless value

    return if value.all? { |domain| domain.match?(VALID_DOMAIN) }

    record.errors.add(attribute, options[:message] || DEFAULT_MESSAGE)
  end
end
