module DataUpdateScripts
  class BackfillUserBlankName
    def run
      User.where(" TRIM(name)='' ").each do |user|
        titleized_username = user.username.titleize
        user.update_column(:name, titleized_username)
      end
    end
  end
end
