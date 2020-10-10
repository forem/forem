class RemoveSupportWebmentionsFromArticles < ActiveRecord::Migration[6.0]
  def change
    safety_assured { remove_column :articles, :support_webmentions, :boolean }
  end
end
