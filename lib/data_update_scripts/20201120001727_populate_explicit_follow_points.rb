module DataUpdateScripts
  class PopulateExplicitFollowPoints
    def run
      Follow.connection.execute('UPDATE "follows" SET "explicit_points" = "points" WHERE points != 1')
      Follow.connection.execute('UPDATE "follows" SET "implicit_points" = 0')
    end
  end
end
