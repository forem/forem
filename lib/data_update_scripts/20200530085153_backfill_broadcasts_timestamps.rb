module DataUpdateScripts
  class BackfillBroadcastsTimestamps
    def run
      # Broadcasts didn't have timestamps columns until
      # 20200530084533_add_timestamps_to_broadcasts was created, thus we can
      # safely assume that only those with `created_at IS NULL` need their
      # timestamps overridden
      Broadcast.where(created_at: nil).order(title: :asc).each do |cast|
        cast.update(created_at: Time.current, updated_at: Time.current)
      end
    end
  end
end
