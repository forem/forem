module DataUpdateScripts
  # The comment embed partial (comments/liquid) now links its date to the comment permalink.
  # Published posts serve stored processed_html, so re-render every record that embeds a comment.
  class RerenderCommentEmbeds
    BATCH_SIZE = 100

    def run
      # Not filtered by tag_name: {% comment %}, {% devcomment %} and {% embed <comment url> %} all
      # render comments/_liquid and are recorded with referenced_type "Comment".
      scope = LiquidEmbedReference.where(referenced_type: "Comment")
      scope.distinct.pluck(:record_type, :record_id).group_by(&:first).each do |record_type, pairs|
        pairs.map(&:last).each_slice(BATCH_SIZE) do |ids|
          RefreshLiquidEmbedRecordsWorker.perform_async(record_type, ids)
        end
      end
    end
  end
end
