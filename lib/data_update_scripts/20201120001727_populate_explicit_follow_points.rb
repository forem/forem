module DataUpdateScripts
  class PopulateExplicitFollowPoints
    def run
      Follow.where("points != 1").find_each do |follow|
        follow.update_column(:explicit_points, follow.points)
      end
    end
  end
end
