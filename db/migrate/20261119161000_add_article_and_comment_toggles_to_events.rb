class AddArticleAndCommentTogglesToEvents < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      change_table :events, bulk: true do |t|
        t.boolean :allow_articles, default: false, null: false
        t.boolean :allow_comments, default: false, null: false
        t.integer :comments_count, default: 0, null: false
      end
    end
  end

  def down
    safety_assured do
      change_table :events, bulk: true do |t|
        t.remove :comments_count, type: :integer
        t.remove :allow_comments, type: :boolean
        t.remove :allow_articles, type: :boolean
      end
    end
  end
end
