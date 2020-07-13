class DeviseInvitableAddToUsers < ActiveRecord::Migration[6.0]
  def up
    safety_assured do
      change_table :users do |t|
        t.string     :invitation_token
        t.boolean    :registered, default: true
        t.datetime   :invitation_created_at
        t.datetime   :invitation_sent_at
        t.datetime   :invitation_accepted_at
        t.integer    :invitation_limit
        t.references :invited_by, polymorphic: true
        t.integer    :invitations_count, default: 0
        t.index      :invitations_count
        t.index      :invitation_token, unique: true # for invitable
        t.index      :invited_by_id
      end
    end
  end

  def down
    safety_assured do
      change_table :users do |t|
        t.remove_references :invited_by, polymorphic: true
        t.remove :invitations_count, :invitation_limit,
                 :invitation_sent_at, :invitation_accepted_at,
                 :invitation_token, :invitation_created_at,
                 :registered
      end
    end
  end
end
