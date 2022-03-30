module Articles
  class ResaveForAssociationWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10, lock: :until_executing

    # @param klass_name [#constantize, String] the name of the class
    # @param id [Object, Integer] the ID of the record for the given class
    def perform(klass_name, id)
      object = klass_name.constantize.find_by(id: id)
      return unless object

      object.articles.find_each(&:save)
    end
  end
end
