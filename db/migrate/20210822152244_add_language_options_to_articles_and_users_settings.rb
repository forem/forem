class AddLanguageOptionsToArticlesAndUsersSettings < ActiveRecord::Migration[6.1]
  def up
    add_column :articles, :text_lang, :string
    add_column :users_settings, :writing_lang, :string
  end

  def down
    safety_assured do
      remove_column :articles, :text_lang
      remove_column :users_settings, :writing_lang
    end
  end
end
