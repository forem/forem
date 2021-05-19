class CreateDiscussionLocks < ActiveRecord::Migration[6.1]
  def change
    create_table :discussion_locks do |t|
      t.references :article, null: false, foreign_key: true, index: { unique: true }
      t.references :user, null: false, foreign_key: true
      t.text :reason

      t.timestamps
    end
  end
end
