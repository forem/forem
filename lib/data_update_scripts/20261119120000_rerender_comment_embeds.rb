module DataUpdateScripts
  # The comment embed partial (comments/liquid) now links its date to the comment permalink.
  # Published posts serve stored processed_html, so re-render every record that embeds a comment.
  class RerenderCommentEmbeds
    BATCH_SIZE = 100
    COMMENT_TAGS = %w[comment devcomment].freeze

    def run
      scope = LiquidEmbedReference.where(tag_name: COMMENT_TAGS, referenced_type: "Comment")
      scope.distinct.pluck(:record_type, :record_id).group_by(&:first).each do |record_type, pairs|
        pairs.map(&:last).each_slice(BATCH_SIZE) do |ids|
          RefreshLiquidEmbedRecordsWorker.perform_async(record_type, ids)
        end
      end
    end
  end
end
