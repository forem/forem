class AddAutomodLabelToArticles < ActiveRecord::Migration[7.0]

  def change
    add_column :articles, :automod_label, :integer, default: 0, null: false unless column_exists?(:articles, :automod_label)
  end
end
