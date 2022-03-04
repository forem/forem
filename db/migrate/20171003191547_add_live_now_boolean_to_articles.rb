class AddLiveNowBooleanToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :live_now, :boolean, default: false
  end
end
