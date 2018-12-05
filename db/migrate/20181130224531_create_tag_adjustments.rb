class CreateTagAdjustments < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_adjustments do |t|
      t.integer   :user_id
      t.integer   :article_id
      t.integer   :tag_id
      t.string    :tag_name
      t.string    :adjustment_type
      t.string    :status
      t.string    :reason_for_adjustment
      t.timestamps
    end
  end
end
