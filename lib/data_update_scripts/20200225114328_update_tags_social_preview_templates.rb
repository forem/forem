module DataUpdateScripts
  class UpdateTagsSocialPreviewTemplates
    def run
      Tag.where(name: %w[shecoded theycoded shecodedally]).update_all(social_preview_template: "shecoded")
    end
  end
end
