module DataUpdateScripts
  class PopulateExplicitFollowPoints
    def run
      # Place your data update logic here
      # Make sure your code is idempotent and can be run safely
      # multiple times at any time
      Follow.where("points != 1").each do |follow|
        follow.update_columns(explicit_points: follow.points)
      end
    end
  end
end
