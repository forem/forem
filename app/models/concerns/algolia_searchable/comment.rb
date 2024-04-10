module AlgoliaSearchable
  module Comment
    extend ActiveSupport::Concern

    included do
      include AlgoliaSearch

      algoliasearch per_environment: true, enqueue: :trigger_sidekiq_worker, if: :good_enough do
        # TODO: make sure all are valid attributes
        attribute :commentable_id, :commentable_type, :path, :readable_publish_date, :parent_id
        attribute :body_html do
          truncate_body_html
        end

        attribute :user do
          { name: user.name, username: user.username, profile_image: user.profile_image_90 }
        end

        add_replica "Comment_ordered", inherit: true, per_environment: true do
          customRanking ["desc(created_at_i)"]
        end
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        # TODO: umm make sure this get called in the appropriate place
        AlgoliaSearch::IndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def truncate_body_html
      # TODO: probably not needed
      # HTML_Truncator.truncate(
      #   processed_html,
      #   500,
      #   ellipsis: '<a class="comment-read-more" href="' + path + '">... Read Entire Comment</a>',
      # )
    end

    def good_enough
      # TODO: actually idk how _changed would work here.
      !hidden_by_commentable_user
    end
    alias good_enough_changed? good_enough
  end
end
