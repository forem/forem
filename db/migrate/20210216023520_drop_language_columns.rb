class DropLanguageColumns < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :articles, :language
      remove_column :users, :language_settings
    end
  end
end
