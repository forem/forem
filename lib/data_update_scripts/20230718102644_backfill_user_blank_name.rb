module DataUpdateScripts
  class BackfillUserBlankName
    def run
      User.where(" TRIM(name)='' ").each do |user|
        user.update_column(:name, user.username)
      end
    end
  end
end
