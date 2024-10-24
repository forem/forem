class CreateEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :emails do |t|
      t.string      :subject, null: false
      t.text        :body, null: false
      t.references  :audience_segment, foreign_key: true
      t.timestamps
    end
  end
end
