module JsonApiSortParams
  def sort_params(param_string, allowed_params:, default_sort:)
    fields = param_string.to_s.split(",")
    unfiltered_hash = fields_to_hash(fields)
    sort = sort_and_filter(unfiltered_hash, allowed_params)
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

  def sort_and_filter(params_hash, allowed_params)
    param_order = allowed_params.each_with_index.to_h
    params_hash.slice(*allowed_params).sort_by { |k, _v| param_order[k] }.to_h
  end
end
