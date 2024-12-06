# frozen_string_literal: true

require 'json'

module RuboCop
  # Converts RuboCop objects to and from the serialization format JSON.
  # @api private
  class CachedData
    def initialize(filename)
      @filename = filename
    end

    def from_json(text)
      deserialize_offenses(JSON.parse(text))
    end

    def to_json(offenses)
      JSON.dump(offenses.map { |o| serialize_offense(o) })
    end

    private

    def serialize_offense(offense)
      status = :uncorrected if %i[corrected corrected_with_todo].include?(offense.status)
      {
        # Calling #to_s here ensures that the serialization works when using
        # other json serializers such as Oj. Some of these gems do not call
        # #to_s implicitly.
        severity: offense.severity.to_s,
        location: {
          begin_pos: offense.location.begin_pos,
          end_pos: offense.location.end_pos
        },
        message:  message(offense),
        cop_name: offense.cop_name,
        status:   status || offense.status
      }
    end

    def message(offense)
      # JSON.dump will fail if the offense message contains text which is not
      # valid UTF-8
      offense.message.dup.force_encoding(::Encoding::UTF_8).scrub
    end

    # Restore an offense object loaded from a JSON file.
    def deserialize_offenses(offenses)
      source_buffer = Parser::Source::Buffer.new(@filename)
      source_buffer.source = File.read(@filename, encoding: Encoding::UTF_8)
      offenses.map! do |o|
        location = location_from_source_buffer(o, source_buffer)
        Cop::Offense.new(o['severity'], location, o['message'], o['cop_name'], o['status'].to_sym)
      end
    end

    def location_from_source_buffer(offense, source_buffer)
      begin_pos = offense['location']['begin_pos']
      end_pos = offense['location']['end_pos']
      if begin_pos.zero? && end_pos.zero?
        Cop::Offense::NO_LOCATION
      else
        Parser::Source::Range.new(source_buffer, begin_pos, end_pos)
      end
    end
  end
end
