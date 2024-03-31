module DataUpdateScripts
  class RenameDisplayAdRolesToBillboards
    def run
      Role.where(resource_type: "DisplayAd").update_all(resource_type: "Billboard")
    end
  end
end
