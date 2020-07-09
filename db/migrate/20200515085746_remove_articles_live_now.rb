class RemoveArticlesLiveNow < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :articles, :live_now, :boolean, default: false }
  end
end
