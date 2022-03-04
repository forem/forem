class CreateHtmlVariants < ActiveRecord::Migration[5.1]
  def change
    create_table :html_variants do |t|
      t.integer   :user_id
      t.string    :group
      t.string    :name
      t.text      :html
      t.string    :target_tag
      t.float     :success_rate, default: 0.0
      t.boolean   :published, default: false
      t.boolean   :approved, default: false
      t.timestamps
    end
  end
end
