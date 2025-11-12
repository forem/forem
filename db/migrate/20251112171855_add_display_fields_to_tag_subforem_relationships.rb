class AddDisplayFieldsToTagSubforemRelationships < ActiveRecord::Migration[7.0]
  def change
    add_column :tag_subforem_relationships, :short_summary, :text
    add_column :tag_subforem_relationships, :pretty_name, :string
    add_column :tag_subforem_relationships, :bg_color_hex, :string
    add_column :tag_subforem_relationships, :text_color_hex, :string
  end
end
