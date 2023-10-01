module Images
  class SocialImageWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 5

    def perform(id, class_name)
      object = class_name.constantize.find(id)
      Images::GenerateSocialImageMagickally.call(object)
      Images::GenerateProfileSocialImageMagickally.call(object) if class_name == "User"
    end
  end
end
