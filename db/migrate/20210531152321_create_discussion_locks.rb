class CreateDiscussionLocks < ActiveRecord::Migration[6.1]
  def change
    create_table :discussion_locks do |t|
      t.references :article, null: false, foreign_key: true, index: { unique: true }
      t.references :locking_user, references: :users, foreign_key: { to_table: :users }, null: false
      t.text :reason
      t.text :notes

      t.timestamps
    end
  end
end
