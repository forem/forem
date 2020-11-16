class RemoveBlocksTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :blocks do |t|
      t.integer   :user_id
      t.text      :input_html
      t.text      :processed_html
      t.text      :published_html
      t.text      :input_css
      t.text      :processed_css
      t.text      :published_css
      t.text      :input_javascript
      t.text      :processed_javascript
      t.text      :published_javascript
      t.string    :title
      t.text      :body_markdown
      t.text      :body_html
      t.boolean   :featured
      t.integer   :featured_number
      t.timestamps null: false
    end
  end
end
