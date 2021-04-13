module JsonApiSortParam
  # Handles JSON API style sort params
  #
  # @param param_string [String] The unmodified request param
  # @param allowed_fields [Array<Symbol>] Fields that can be sorted by. This
  #   array determines the sort order of the resulting hash.
  # @param default_sort [{Symbol => Symbol}] The default sort order. Used when
  #   the param string is nil/empty or when parsing it results in an empty hash.
  def parse_sort_param(param_string, allowed_fields:, default_sort:)
    fields = param_string.to_s.split(",")
    unfiltered_hash = fields_to_hash(fields)
    sort = sort_and_filter(unfiltered_hash, allowed_fields)
    sort.presence || default_sort
  end

  private

  def fields_to_hash(fields)
    fields.each_with_object({}) do |field, result|
      if field.start_with?("-")
        result[field[1..]] = :desc
      else
        result[field] = :asc
      end
    end.symbolize_keys
  end

  def sort_and_filter(fields_hash, allowed_fields)
    field_order = allowed_fields.each_with_index.to_h
    fields_hash.slice(*allowed_fields).sort_by { |k, _v| field_order[k] }.to_h
  end
end
