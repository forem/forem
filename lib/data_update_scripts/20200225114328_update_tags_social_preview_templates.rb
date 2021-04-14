module DataUpdateScripts
  class UpdateTagsSocialPreviewTemplates
    def run
      # This script references the shecoded campaign, which has been removed from the app code entirely.

      # Tag.where(name: %w[shecoded theycoded shecodedally]).update_all(social_preview_template: "shecoded")
    end
  end
end
