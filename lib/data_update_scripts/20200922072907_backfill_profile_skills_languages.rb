module DataUpdateScripts
  class BackfillProfileSkillsLanguages
    def run
      User.where.not(mostly_work_with: [nil, ""]).find_each do |user|
        user.profile.update(skills_languages: user.mostly_work_with)
      end
    end
  end
end
