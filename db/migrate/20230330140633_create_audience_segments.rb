class CreateAudienceSegments < ActiveRecord::Migration[7.0]
  def change
    create_table :audience_segments do |t|
      t.integer :type_of

      t.timestamps
    end
  end
end
