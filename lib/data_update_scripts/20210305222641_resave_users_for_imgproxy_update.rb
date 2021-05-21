module DataUpdateScripts
  class ResaveUsersForImgproxyUpdate
    def run
      return if ForemInstance.dev_to?

      User.find_each(&:save)
    end
  end
end
