class AddAllowArticlesToEvents < ActiveRecord::Migration[8.0]
  def up
    add_column :events, :allow_articles, :boolean, default: false, null: false
  end

  def down
    safety_assured do
      remove_column :events, :allow_articles, :boolean
    end
  end
end
