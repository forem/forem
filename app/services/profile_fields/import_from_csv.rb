module ProfileFields
  class ImportFromCsv
    HEADERS = %i[label input_type placeholder_text description group].freeze

    def self.call(file)
      CSV.foreach(file, headers: HEADERS, skip_blanks: true) do |row|
        row = row.to_h
        row[:profile_field_group] = ProfileFieldGroup.find_or_create_by(name: row[:group])
        ProfileField.create(row)
      end
    end
  end
end
