module DataUpdateScripts
  class StrippingHtmlTagsFromTagShortSummary
    def run
      Tag.where("short_summary LIKE '%<%'").find_each do |tag|
        # Choosing to skip validations and mimic the newly added before_validation behavior.
        new_short_summary = ActionController::Base.helpers.strip_tags(tag.short_summary)
        tag.update_columns(short_summary: new_short_summary)
      end
    end
  end
end
