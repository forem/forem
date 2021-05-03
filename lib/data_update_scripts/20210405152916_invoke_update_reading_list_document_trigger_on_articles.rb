module DataUpdateScripts
  class InvokeUpdateReadingListDocumentTriggerOnArticles
    def run
      return unless ActiveRecord::Base.connection.column_exists?(:articles, :reading_list_document)

      # by updating `reading_list_document` to `NULL`,
      # we invoke the `update_reading_list_document` trigger, bypassing Rails callbacks
      Article.in_batches.update_all(reading_list_document: nil)
    end
  end
end
