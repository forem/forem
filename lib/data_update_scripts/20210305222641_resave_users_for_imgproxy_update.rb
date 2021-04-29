module DataUpdateScripts
  class ResaveUsersForImgproxyUpdate
    def run
      return if Settings::General.dev_to?

      User.find_each(&:save)
    end
  end
end
