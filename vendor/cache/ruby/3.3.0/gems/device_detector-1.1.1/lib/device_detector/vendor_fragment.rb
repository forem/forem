# frozen_string_literal: true

require 'set'

class DeviceDetector
  class VendorFragment < Parser
    def name
      vendor_fragment_info
    end

    private

    def vendor_fragment_info
      from_cache(['vendor_fragment', self.class.name, user_agent]) do
        return if regex_meta.nil? || regex_meta.empty?

        regex_meta[:regex_name]
      end
    end

    def filenames
      ['vendorfragments.yml']
    end
  end
end
