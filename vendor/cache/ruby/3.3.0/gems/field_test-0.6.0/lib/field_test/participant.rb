module FieldTest
  class Participant
    attr_reader :type, :id

    def initialize(object)
      if object.is_a?(FieldTest::Participant)
        @type = object.type
        @id = object.id
      elsif object.respond_to?(:model_name)
        @type = object.model_name.name
        @id = object.id.to_s
      else
        @id = object.to_s
      end
    end

    def participant
      [type, id].compact.join(":")
    end

    def where_values
      if FieldTest.legacy_participants
        {
          participant: participant
        }
      else
        {
          participant_type: type,
          participant_id: id
        }
      end
    end

    def self.standardize(participant)
      Array(participant).compact.map { |v| FieldTest::Participant.new(v) }
    end
  end
end
