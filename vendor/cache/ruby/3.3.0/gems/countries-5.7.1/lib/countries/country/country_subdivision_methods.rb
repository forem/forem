# frozen_string_literal: true

module ISO3166
  module CountrySubdivisionMethods
    # @param subdivision_str [String] A subdivision name or code to search for. Search includes translated subdivision names.
    # @return [Subdivision] The first subdivision matching the provided string
    def find_subdivision_by_name(subdivision_str)
      subdivisions.select do |k, v|
        subdivision_str == k || v.name == subdivision_str || v.translations.values.include?(subdivision_str)
      end.values.first
    end

    def subdivision_for_string?(subdivision_str)
      !subdivisions.transform_values(&:translations)
                   .select { |k, v| subdivision_str == k || v.values.include?(subdivision_str) }.empty?
    end

    #  +true+ if this Country has any Subdivisions.
    def subdivisions?
      !subdivisions.empty?
    end

    # @return [Array<ISO3166::Subdivision>] the list of subdivisions for this Country.
    def subdivisions
      @subdivisions ||= if data['subdivisions']
                          ISO3166::Data.create_subdivisions(data['subdivisions'])
                        else
                          ISO3166::Data.subdivisions(alpha2)
                        end
    end

    # @param types [Array<String>] The locale to use for translations.
    # @return [Array<ISO3166::Subdivision>] the list of subdivisions of the given type(s) for this Country.
    def subdivisions_of_types(types)
      subdivisions.select { |_k, v| types.include?(v.type) }
    end

    # @return [Array<String>] the list of subdivision types for this country
    def subdivision_types
      subdivisions.map { |_k, v| v['type'] }.uniq
    end

    # @return [Array<String>] the list of humanized subdivision types for this country. Uses ActiveSupport's `#humanize` if available
    def humanized_subdivision_types
      if String.instance_methods.include?(:humanize)
        subdivisions.map { |_k, v| v['type'].humanize }.uniq
      else
        subdivisions.map { |_k, v| humanize_string(v['type']) }.uniq
      end
    end

    # @param locale [String] The locale to use for translations.
    # @return [Array<Array>] This Country's subdivision pairs of names and codes.
    def subdivision_names_with_codes(locale = 'en')
      subdivisions.map { |k, v| [v.translations[locale] || v.name, k] }
    end

    # @param locale [String] The locale to use for translations.
    # @return [Array<String>] A list of subdivision names for this country.
    def subdivision_names(locale = 'en')
      subdivisions.map { |_k, v| v.translations[locale] || v.name }
    end

    def states
      if RUBY_VERSION =~ /^3\.\d\.\d/
        warn 'DEPRECATION WARNING: The Country#states method has been deprecated and will be removed in 6.0. Please use Country#subdivisions instead.',
             uplevel: 1, category: :deprecated
      else
        warn 'DEPRECATION WARNING: The Country#states method has been deprecated and will be removed in 6.0. Please use Country#subdivisions instead.',
             uplevel: 1
      end

      subdivisions
    end

    private

    def humanize_string(str)
      str[0].upcase + str.tr('_', ' ')[1..]
    end
  end
end
