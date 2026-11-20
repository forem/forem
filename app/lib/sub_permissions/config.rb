module SubPermissions
  class Config
    KEYS = %w[allow version].freeze

    attr_reader :resource_type, :errors

    def initialize(raw, resource_type:)
      @raw = raw
      @resource_type = resource_type.to_s
      @errors = validate
    end

    def valid?
      errors.empty?
    end

    def allows?(clause)
      valid? && @raw["allow"].include?(clause.to_s)
    end

    private

    def validate
      return [error(:not_configurable)] unless SubPermissions.configurable?(resource_type)
      return [error(:malformed)] unless @raw.is_a?(Hash) && @raw.keys.all?(String) && @raw.keys.sort == KEYS
      return [error(:unsupported_version)] unless @raw["version"] == SubPermissions::VERSION

      allow = @raw["allow"]
      return [error(:malformed)] unless allow.is_a?(Array) && allow.all?(String)
      return [error(:malformed)] unless allow.uniq.size == allow.size

      unknown = allow - SubPermissions.clauses_for(resource_type)
      return [] if unknown.empty?

      [error(:unknown_clauses, clauses: unknown.to_sentence)]
    end

    def error(key, **options)
      I18n.t("lib.sub_permissions.errors.#{key}", resource: resource_type, **options)
    end
  end
end
