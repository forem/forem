class AddSurveyRefernceToPolls < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :polls, :survey, null: true, index: {algorithm: :concurrently}
  end
end