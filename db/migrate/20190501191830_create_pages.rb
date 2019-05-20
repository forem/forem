class CreatePages < ActiveRecord::Migration[5.2]
  def change
    create_table :pages do |t|
      t.string    :title
      t.text      :body_markdown
      t.text      :body_html
      t.text      :processed_html
      t.string    :slug
      t.string    :description
      t.string    :social_image
      t.string    :template
      t.string    :group
      t.integer   :group_order_number
      t.timestamps
    end
  end
end
