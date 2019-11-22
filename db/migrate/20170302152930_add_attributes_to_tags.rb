class AddAttributesToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :wiki_body_markdown, :text
    add_column :tags, :wiki_body_html, :text
    add_column :tags, :rules_markdown, :text
    add_column :tags, :rules_html, :text
    add_column :tags, :short_summary, :string
    add_column :tags, :requires_approval, :boolean, default: false
    add_column :tags, :submission_template, :text
    add_column :tags, :submission_rules_headsup, :string
    add_column :tags, :pretty_name, :string
    add_column :tags, :profile_image, :string
    add_column :tags, :bg_color_hex, :string
    add_column :tags, :text_color_hex, :string
  end
end
