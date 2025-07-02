Rails.application.config.to_prepare do
  # Step 2: Define a module to override the click method
  module Ahoy # rubocop:disable Lint/ConstantDefinitionInBlock
    module MessagesControllerMonkeyPatch
      def click
        # Check if params[:url] includes the :bb parameter
        url = params[:u] || params[:url]
        if url.present? && URI.parse(url).query.to_s.include?("bb=")
          bb = URI.parse(url).query.to_s.scan(/(?<=\A|&)bb=([^&]*)/).flatten.last
          Billboards::TrackEmailClickWorker.perform_async(bb, current_user&.id)
        end
        # Call the original click method
        super
      end
    end
  end

  # Step 4: Prepend the module to Ahoy::MessagesController
  Ahoy::MessagesController.prepend Ahoy::MessagesControllerMonkeyPatch
end
