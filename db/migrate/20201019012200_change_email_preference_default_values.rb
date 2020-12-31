class ChangeEmailPreferenceDefaultValues < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:users, :email_newsletter, from: true, to: false)
    change_column_default(:users, :email_digest_periodic, from: true, to: false)
  end
end
