module DataUpdateScripts
  class PopulateExplicitFollowPoints
    def run
      Follow.connection.execute('UPDATE "follows" SET "explicit_points" = "points" WHERE points != 1')
    end
  end
end
