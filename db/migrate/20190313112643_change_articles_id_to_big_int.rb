class ChangeArticlesIdToBigInt < ActiveRecord::Migration[5.1]
  def up
    change_column :articles, :id, :bigint
  end

  def down
    change_column :articles, :id, :integer
  end
end
