class CreateCredits < ActiveRecord::Migration[5.1]
  def change
    create_table :credits do |t|
      t.bigint    :user_id
      t.bigint    :organization_id
      t.float     :cost, default: 0.0
      t.string    :spent_on
      t.boolean   :spent, default: false
      t.timestamps
    end
  end
end
