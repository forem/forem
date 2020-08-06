module ProfileFields
  class ImportFromCsv
    HEADERS = %i[label input_type placeholder_text description group].freeze

    def self.call(file)
      CSV.foreach(file, headers: HEADERS, skip_blanks: true) do |row|
        ProfileField.create(row.to_h)
      end
    end
  end
end
