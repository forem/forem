module Tags
  class AliasRetagWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 5

    def perform(tag_id)
      tag = Tag.find_by(id: tag_id)
      return unless tag

      tag.taggings.find_each do |tagging|
        taggable = tagging.taggable
        next unless taggable

        new_tag_list = ActsAsTaggableOn::TagParser.new(taggable.tag_list).parse
        taggable.update(tag_list: new_tag_list)
      end
    end
  end
end
