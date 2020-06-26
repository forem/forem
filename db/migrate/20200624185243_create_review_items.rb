class CreateReviewItems < ActiveRecord::Migration[6.0]
  def change
    create_table :review_items do |t|
      t.references :reviewable, polymorphic: true, null: false, index: { name: :index_on_reviewable_type_and_id }
      t.references :reviewer, references: :users, foreign_key: { to_table: :users }
      t.boolean :reviewed, null: false, default: false
      t.boolean :read, null: false, default: false
      t.string :action_taken

      t.timestamps
    end

    add_index(
      :review_items,
      %i[reviewer_id reviewable_id reviewable_type],
      unique: true,
      name: :index_on_reviewer_id_reviewable_type_and_id
    )
  end
end
