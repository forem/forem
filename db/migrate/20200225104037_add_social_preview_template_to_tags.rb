class AddSocialPreviewTemplateToTags < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :social_preview_template, :string, default: "article"
  end
end
