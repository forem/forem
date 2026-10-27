module Images
  class SocialImageWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 5, lock: :until_executing, on_conflict: :replace

    def perform(id, class_name)
      object = class_name.constantize.find_by(id: id)
      return unless object

      Images::GenerateSocialImageMagickally.call(object)
    end
  end
end
