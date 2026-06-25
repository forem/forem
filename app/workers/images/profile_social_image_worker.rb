module Images
  class ProfileSocialImageWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 5, lock: :until_executing, on_conflict: :replace

    def perform(id, class_name)
      object = class_name.constantize.find(id)
      Images::GenerateProfileSocialImageMagickally.call(object)
    end
  end
end
