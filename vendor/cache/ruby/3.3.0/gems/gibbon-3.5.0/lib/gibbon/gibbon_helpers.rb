module Gibbon
  module Helpers
    def get_data_center_from_api_key(api_key)
      # Return an empty string for invalid API keys so Gibbon hits the main endpoint
      data_center = ""

      if api_key && api_key["-"]
        # Remove all non-alphanumberic characters in case someone attempts to inject
        # a different domain into the API key (e.g. when consuming user form-provided keys)
        # This approach avoids assuming a 3 letter prefix (e.g. is MC were to create 
        # a us10 DC, this would continue to work), and will continue to hit MC's server
        # rather than a would-be attacker's servers.
        data_center = "#{api_key.split('-').last.gsub(/[^0-9a-z ]/i, '')}."
      end

      data_center
    end
  end
end