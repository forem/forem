module Images
  class SocialImageWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 5

    def perform(id, class_name)
      object = class_name.constantize.find(id)
      Images::GenerateSocialImage.call(object)
    end
  end
end
