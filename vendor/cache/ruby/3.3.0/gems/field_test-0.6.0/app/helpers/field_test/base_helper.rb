module FieldTest
  module BaseHelper
    def field_test_participant_link(membership)
      if FieldTest.legacy_participants
        link_to membership.participant, legacy_participant_path(membership.participant)
      else
        text = [membership.participant_type, membership.participant_id].compact.join(" ")
        link_to text, participant_path(type: membership.participant_type, id: membership.participant_id)
      end
    end
  end
end
