class AddAltToSponsors < ActiveRecord::Migration[4.2]
  def change
    add_column :sponsors, :alt_subheadline, :string
    add_column :articles, :alt_description, :text
    add_column :articles, :alt_image, :string
    add_column :articles, :lead_phrase, :string, default: "Sponsored by a service we love"
    add_column :articles, :alt_lead_phrase, :string, default: "Sponsored by a service we love"
    add_column :articles, :button_text, :string, default: "Learn More"
    add_column :articles, :alt_button_text, :string, default: "Learn More"

  end
end
