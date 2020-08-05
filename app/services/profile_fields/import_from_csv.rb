module ProfileFields
  class ImportFromCsv
    HEADERS = %i[label input_type placeholder_text description].freeze

    def self.call(file)
      new(file).import
    end

    attr_reader :file

    def initialize(file)
      @file = file
    end

    def import
      CSV.foreach(file, headers: HEADERS, skip_blanks: true) do |row|
        ProfileField.create(row.to_h)
      end
    end
  end
end
