module DataUpdateScripts
  class BackfillLastActiveAtForBroadcasts
    def run
      # Broadcasts didn't have a last_active_at column until
      # 20200609195523_add_last_active_at_to_broadcasts was created, thus we can
      # safely assume that only those with `last_active_at IS NULL` need their
      # timestamps overridden.
      # This updates the Broadcast's last_active_at to be the date and time
      # in which the Broadcast was last updated.
      Broadcast.where(last_active_at: nil).order(title: :asc).each do |cast|
        cast.update(last_active_at: cast.updated_at)
      end
    end
  end
end
