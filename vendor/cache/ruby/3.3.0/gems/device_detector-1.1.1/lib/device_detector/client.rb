# frozen_string_literal: true

class DeviceDetector
  class Client < Parser
    def known?
      regex_meta.any?
    end

    def browser?
      regex_meta[:path] == :"client/browsers.yml"
    end

    def mobile_only_browser?
      DeviceDetector::Browser.mobile_only_browser?(name)
    end

    private

    def filenames
      [
        'client/feed_readers.yml',
        'client/mobile_apps.yml',
        'client/mediaplayers.yml',
        'client/pim.yml',
        'client/browsers.yml',
        'client/libraries.yml'
      ]
    end
  end
end
