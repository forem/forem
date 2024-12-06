# frozen_string_literal: true

module I18n::Tasks::Configuration # rubocop:disable Metrics/ModuleLength
  DEFAULTS = {
    base_locale: 'en',
    internal_locale: 'en',
    search: ::I18n::Tasks::UsedKeys::SEARCH_DEFAULTS,
    data: ::I18n::Tasks::Data::DATA_DEFAULTS
  }.freeze

  # i18n-tasks config (defaults + config/i18n-tasks.yml)
  # @return [Hash{String => String,Hash,Array}]
  def config
    @config || (self.config = {})
  end

  CONFIG_FILES = %w[
    config/i18n-tasks.yml config/i18n-tasks.yml.erb
    i18n-tasks.yml i18n-tasks.yml.erb
  ].freeze

  def file_config
    file   = @config_override || CONFIG_FILES.detect { |f| File.exist?(f) }
    # rubocop:disable Security/Eval
    config = file && YAML.load(eval(Erubi::Engine.new(File.read(file, encoding: 'UTF-8')).src))
    # rubocop:enable Security/Eval
    if config.present?
      config.with_indifferent_access.tap do |c|
        if c[:relative_roots]
          warn_deprecated 'Please move relative_roots under search in config/i18n-tasks.yml.'
          c[:search][:relative_roots] = c.delete(:relative_roots)
        end

        if c.dig(:search, :exclude_method_name_paths)
          warn_deprecated(
            'Please rename exclude_method_name_paths to relative_exclude_method_name_paths in config/i18n-tasks.yml.'
          )
          c[:search][:relative_exclude_method_name_paths] = c[:search].delete(:exclude_method_name_paths)
        end
      end
    else
      {}.with_indifferent_access
    end
  end

  def config=(conf)
    @config = file_config.deep_merge(conf)
    @config_sections = {}
  end

  # data config
  #  @return [Hash<adapter: String, options: Hash>]
  def data_config
    @config_sections[:data] ||= {
      adapter: data.class.name,
      config: data.config
    }
  end

  # translation config
  # @return [Hash{String => String,Hash,Array}]
  def translation_config
    @config_sections[:translation] ||= begin
      conf = (config[:translation] || {}).with_indifferent_access
      conf[:google_translate_api_key] = ENV['GOOGLE_TRANSLATE_API_KEY'] if ENV.key?('GOOGLE_TRANSLATE_API_KEY')
      conf[:deepl_api_key] = ENV['DEEPL_AUTH_KEY'] if ENV.key?('DEEPL_AUTH_KEY')
      conf[:deepl_host] = ENV['DEEPL_HOST'] if ENV.key?('DEEPL_HOST')
      conf[:deepl_version] = ENV['DEEPL_VERSION'] if ENV.key?('DEEPL_VERSION')
      conf[:openai_api_key] = ENV['OPENAI_API_KEY'] if ENV.key?('OPENAI_API_KEY')
      conf[:yandex_api_key] = ENV['YANDEX_API_KEY'] if ENV.key?('YANDEX_API_KEY')
      conf
    end
  end

  # @return [Array<String>] all available locales, base_locale is always first
  def locales
    @config_sections[:locales] ||= data.locales
  end

  # @return [String] default i18n locale
  def base_locale
    @config_sections[:base_locale] ||= (config[:base_locale] || DEFAULTS[:base_locale]).to_s
  end

  def internal_locale
    @config_sections[:internal_locale] ||= begin
      internal_locale = (config[:internal_locale] || DEFAULTS[:internal_locale]).to_s
      valid_locales = Dir[File.join(I18n::Tasks.gem_path, 'config', 'locales', '*.yml')]
                      .map { |f| File.basename(f, '.yml') }
      unless valid_locales.include?(internal_locale)
        log_warn "invalid internal_locale #{internal_locale.inspect}. " \
                 "Available internal locales: #{valid_locales * ', '}."
        internal_locale = DEFAULTS[:internal_locale].to_s
      end
      internal_locale
    end
  end

  def ignore_config(type = nil)
    key = type ? "ignore_#{type}" : 'ignore'
    @config_sections[key] ||= config[key]
  end

  IGNORE_TYPES = [nil, :missing, :unused, :eq_base].freeze
  # evaluated configuration (as the app sees it)
  def config_sections
    # init all sections
    base_locale
    internal_locale
    locales
    data_config
    @config_sections[:search] ||= search_config
    translation_config
    IGNORE_TYPES.each do |ignore_type|
      ignore_config ignore_type
    end
    @config_sections
  end

  def config_for_inspect
    to_hash_from_indifferent(config_sections.reject { |_k, v| v.blank? }).tap do |sections|
      sections.each_value do |section|
        section.merge! section.delete('config') if section.is_a?(Hash) && section.key?('config')
      end
    end
  end

  private

  def to_hash_from_indifferent(value)
    case value
    when Hash
      value.stringify_keys.to_hash.tap do |h|
        h.each { |k, v| h[k] = to_hash_from_indifferent(v) if v.is_a?(Hash) || v.is_a?(Array) }
      end
    when Array
      value.map { |e| to_hash_from_indifferent e }
    else
      value
    end
  end
end
