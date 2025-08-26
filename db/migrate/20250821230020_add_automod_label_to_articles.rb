class AddAutomodLabelToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :articles, :automod_label, :integer, default: 0, null: false
    add_index :articles, :automod_label, algorithm: :concurrently
  end
end
