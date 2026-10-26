class CreateCoAuthorInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :co_author_invitations do |t|
      t.references :article, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :status, null: false, default: "pending"
      t.datetime :responded_at

      t.timestamps
    end

    # Leading article_id also serves the per-article lookups, so no separate article_id index.
    add_index :co_author_invitations, %i[article_id user_id], unique: true
  end
end
