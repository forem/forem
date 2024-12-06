# frozen_string_literal: true

class DeviceDetector
  class Bot < Parser
    def bot?
      regex_meta.any?
    end

    private

    def filenames
      ['bots.yml']
    end
  end
end
