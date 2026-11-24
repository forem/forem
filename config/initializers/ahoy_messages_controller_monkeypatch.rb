Rails.application.config.to_prepare do
  # Step 2: Define a module to override the click method
  module Ahoy # rubocop:disable Lint/ConstantDefinitionInBlock
    module MessagesControllerMonkeyPatch
      def click
        # Check if params[:url] includes the :bb parameter
        url = params[:u] || params[:url]
        query = ahoy_click_url_query(url)
        if query.include?("bb=")
          bb = query.scan(/(?<=\A|&)bb=([^&]*)/).flatten.last
          Billboards::TrackEmailClickWorker.perform_async(bb, current_user&.id, request.user_agent)
        end
        # Call the original click method
        super
      end

      private

      def ahoy_click_url_query(url)
        return "" unless url.is_a?(String) && url.present?

        URI.parse(url).query.to_s
      rescue URI::Error
        ""
      end
    end
  end

  # Step 4: Prepend the module to Ahoy::MessagesController
  Ahoy::MessagesController.prepend Ahoy::MessagesControllerMonkeyPatch
end
