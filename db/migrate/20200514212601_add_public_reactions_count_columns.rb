class AddPublicReactionsCountColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :public_reactions_count, :integer, default: 0, null: false
    add_column :articles, :previous_public_reactions_count, :integer, default: 0, null: false

    add_column :comments, :public_reactions_count, :integer, default: 0, null: false
  end
end
