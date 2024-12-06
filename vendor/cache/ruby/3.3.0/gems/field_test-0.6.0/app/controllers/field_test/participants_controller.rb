module FieldTest
  class ParticipantsController < BaseController
    def show
      # TODO better ordering
      @memberships =
        if FieldTest.legacy_participants
          @participant = params[:id]
          FieldTest::Membership.where(participant: @participant).order(:id)
        else
          id = params[:id]
          type = params[:type]
          @participant = [type, id].compact.join(" ")
          FieldTest::Membership.where(participant_type: type, participant_id: id).order(:id)
        end

      @events =
        if FieldTest.events_supported?
          FieldTest::Event.where(field_test_membership_id: @memberships.map(&:id)).group(:field_test_membership_id, :name).count
        else
          {}
        end
    end
  end
end
