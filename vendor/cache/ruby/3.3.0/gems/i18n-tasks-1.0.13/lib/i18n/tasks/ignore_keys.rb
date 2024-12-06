# frozen_string_literal: true

module I18n::Tasks::IgnoreKeys
  # whether to ignore the key
  # will also apply global ignore rules
  # @param [:missing, :unused, :eq_base] ignore_type
  def ignore_key?(key, ignore_type, locale = nil)
    key =~ ignore_pattern(ignore_type, locale)
  end

  # @param type [nil, :missing, :unused, :eq_base] type
  # @param locale [String] only when type is :eq_base
  # @return [Regexp] a regexp that matches all the keys ignored for the type (and locale)
  def ignore_pattern(type, locale = nil)
    @ignore_patterns              ||= HashWithIndifferentAccess.new
    @ignore_patterns[type]        ||= {}
    @ignore_patterns[type][locale] ||= begin
      global = ignore_config.presence || []
      type_ignore = ignore_config(type).presence || []
      patterns = case type_ignore
                 when Array
                   global + type_ignore
                 when Hash
                   # ignore per locale
                   global + (type_ignore['all'] || []) +
                   type_ignore.select { |k, _v| k.to_s =~ /\b#{locale}\b/ }.values.flatten(1).compact
                 end
      compile_patterns_re patterns
    end
  end
end
