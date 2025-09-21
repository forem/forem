module I18nHelper
  # Builds i18n translations hash with conditional loading based on controller/action
  #
  # This method ensures that only the necessary i18n translations are loaded
  # for each page, improving performance by reducing the JavaScript payload.
  #
  # @return [Hash] Translations hash with core translations and conditional page-specific translations
  #
  # @example
  #   # In a view template:
  #   <div id="i18n-translations" data-translations="<%= i18n_translations_for_javascript.to_json %>"></div>
  def i18n_translations_for_javascript
    translations = {
      I18n.locale.to_sym => {
        core: I18n::JS.translations[I18n.locale.to_sym][:core]
      }
    }

    # Add conditional translations based on controller/action
    add_conditional_translations(translations)

    translations
  end

  private

  # Adds conditional translations based on the current page context
  #
  # @param translations [Hash] The base translations hash to modify
  def add_conditional_translations(translations)
    # Home feed page - include no-results translations
    return unless home_feed_page?

    translations[I18n.locale.to_sym][:views] = {
      stories: {
        feed: {
          no_results: I18n.t("views.stories.feed.no_results")
        }
      }
    }

    # Add more conditional translations here as needed
    # Example:
    # if articles_show_page?
    #   translations[I18n.locale.to_sym][:views] ||= {}
    #   translations[I18n.locale.to_sym][:views][:articles] = {
    #     actions: I18n.t('views.articles.actions')
    #   }
    # end
  end

  # Determines if the current page is the home feed page
  #
  # @return [Boolean] true if on stories#index, false otherwise
  def home_feed_page?
    controller_name == "stories" && action_name == "index" && @home_page == true
  end

  # Add more page detection methods as needed
  # def articles_show_page?
  #   controller_name == 'articles' && action_name == 'show'
  # end
end
