module DataUpdateScripts
  # The comment embed partial (comments/liquid) now links its date to the comment permalink.
  # Published posts serve stored processed_html, so every record that embeds a comment must be re-rendered.
  # The worker walks the tables in bounded id ranges, one job at a time, and only writes HTML that changed,
  # so running it again is safe.
  class RerenderCommentEmbeds
    def run
      RerenderCommentEmbedsWorker.perform_async(RerenderCommentEmbedsWorker::RECORD_TYPES.first, 0)
    end
  end
end
