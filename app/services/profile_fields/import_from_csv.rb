module ProfileFields
  class ImportFromCsv
    HEADERS = %i[label input_type placeholder_text description group display_area].freeze

    def self.call(file)
      CSV.foreach(file, headers: HEADERS, skip_blanks: true) do |row|
        row = row.to_h
        group = row.delete(:group)
        row[:profile_field_group] = ProfileFieldGroup.find_or_create_by(name: group)
        ProfileField.find_or_create_by(row)
      end
      Profile.refresh_attributes!
    end
  end
end
