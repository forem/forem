class RemoveProfileColumnsFromUser < ActiveRecord::Migration[6.0]
  def change
    # rubocop:disable Metrics/Blocklength
    safety_assured do
      remove_column :users, :available_for
      remove_column :users, :behance_url
      remove_column :users, :bg_color_hex
      remove_column :users, :currently_hacking_on
      remove_column :users, :currently_learning
      remove_column :users, :dribbble_url
      remove_column :users, :education
      remove_column :users, :email_public
      remove_column :users, :employer_name
      remove_column :users, :employer_url
      remove_column :users, :employment_title
      remove_column :users, :facebook_url
      remove_column :users, :gitlab_url
      remove_column :users, :instagram_url
      remove_column :users, :linkedin_url
      remove_column :users, :location
      remove_column :users, :mastodon_url
      remove_column :users, :medium_url
      remove_column :users, :mostly_work_with
      remove_column :users, :stackoverflow_url
      remove_column :users, :summary
      remove_column :users, :text_color_hex
      remove_column :users, :twitch_url
      remove_column :users, :website_url
      remove_column :users, :youtube_url
    end
    # rubocop:enable Metrics/Blocklength
  end
end
