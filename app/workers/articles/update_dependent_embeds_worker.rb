module Articles
  class UpdateDependentEmbedsWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(article_id)
      LiquidEmbedReference.where(referenced_type: ["Article", nil], referenced_id: article_id).find_each do |reference|
        record = reference.record
        next unless record

        original_html = record.processed_html

        if record.is_a?(Article)
          record.evaluate_and_update_column_from_markdown
          if original_html != record.processed_html
            record.async_bust
          end
        elsif record.respond_to?(:evaluate_markdown, true) && record.respond_to?(:processed_html=)
          record.send(:evaluate_markdown)
          if original_html != record.processed_html
            record.update_column(:processed_html, record.processed_html)
            
            if record.respond_to?(:async_bust)
              record.async_bust
            elsif record.respond_to?(:bust_cache)
              record.send(:bust_cache)
            end
          end
        end
      end
    end
  end
end
