class RenamePrimaryStreamTextToUrlOnEvents < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      rename_column :events, :primary_stream_text, :primary_stream_url
      change_column :events, :primary_stream_url, :text
    end
  end

  def down
    safety_assured do
      change_column :events, :primary_stream_url, :string
      rename_column :events, :primary_stream_url, :primary_stream_text
    end
  end
end
