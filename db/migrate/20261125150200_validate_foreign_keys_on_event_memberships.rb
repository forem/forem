class ValidateForeignKeysOnEventMemberships < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :event_memberships, :events, column: :parent_event_id
    validate_foreign_key :event_memberships, :events, column: :child_event_id
  end
end
