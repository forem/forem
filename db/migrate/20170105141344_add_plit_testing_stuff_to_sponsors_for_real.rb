class AddPlitTestingStuffToSponsorsForReal < ActiveRecord::Migration
  def change
    remove_column :articles, :alt_description, :text
    remove_column :articles, :alt_image, :string
    remove_column :articles, :lead_phrase, :string, default: "Sponsored by a service we love"
    remove_column :articles, :alt_lead_phrase, :string, default: "Sponsored by a service we love"
    remove_column :articles, :button_text, :string, default: "Learn More"
    remove_column :articles, :alt_button_text, :string, default: "Learn More"

    add_column :sponsors, :alt_description, :text
    add_column :sponsors, :alt_image, :string
    add_column :sponsors, :lead_phrase, :string, default: "Sponsored by a service we love"
    add_column :sponsors, :alt_lead_phrase, :string, default: "Sponsored by a service we love"
    add_column :sponsors, :button_text, :string, default: "Learn More"
    add_column :sponsors, :alt_button_text, :string, default: "Learn More"
    add_column :sponsors, :currently_split_testing, :boolean, default: false
    add_column :sponsors, :version_name, :string, default: "v0"
    add_column :sponsors, :alt_version_name, :string, default: "v1"

  end
end
