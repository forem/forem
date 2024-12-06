# frozen_string_literal: true

class DeviceDetector
  class ClientHint
    ROOT = File.expand_path('../..', __dir__)

    REGEX_CACHE = ::DeviceDetector::MemoryCache.new({})
    private_constant :REGEX_CACHE

    class HintBrowser < Struct.new(:name, :version)
    end

    def initialize(headers)
      return if headers.nil?

      @headers = headers
      @full_version = headers['Sec-CH-UA-Full-Version']
      @browser_list = extract_browser_list
      @app_name = extract_app_name
      @platform = headers['Sec-CH-UA-Platform']
      @platform_version = extract_platform_version
      @mobile = headers['Sec-CH-UA-Mobile']
      @model = extract_model
    end

    attr_reader :app_name, :browser_list, :full_version, :headers, :mobile, :model, :platform,
                :platform_version

    def browser_name
      return 'Iridium' if is_iridium?

      browser_name_from_list || app_name
    end

    def os_version
      return windows_version if platform == 'Windows'

      platform_version
    end

    def os_name
      return 'Android' if android_app?
      return unless ['Windows', 'Chromium OS'].include?(platform)

      platform
    end

    def os_short_name
      return if os_name.nil?

      DeviceDetector::OS::DOWNCASED_OPERATING_SYSTEMS[os_name.downcase]
    end

    def os_family
      return if os_short_name.nil?

      DeviceDetector::OS::FAMILY_TO_OS[os_short_name]
    end

    private

    def extract_platform_version
      return if  headers['Sec-CH-UA-Platform-Version'].nil?
      return if  headers['Sec-CH-UA-Platform-Version'] == ''

      headers['Sec-CH-UA-Platform-Version']
    end

    # https://github.com/matomo-org/device-detector/blob/28211c6f411528abf41304e07b886fdf322a49b7/Parser/OperatingSystem.php#L330
    def android_app?
      %w[com.hisense.odinbrowser com.seraphic.openinet.pre
         com.appssppa.idesktoppcbrowser].include?(app_name_from_headers)
    end

    def browser_name_from_list
      @browser_name_from_list ||= browser_list&.reject { |b| b.name == 'Chromium' }&.last&.name
    end

    def available_browsers
      DeviceDetector::Browser::AVAILABLE_BROWSERS.values
    end

    def available_osses
      DeviceDetector::OS::OPERATING_SYSTEMS.values
    end

    # https://github.com/matomo-org/device-detector/blob/28211c6f411528abf41304e07b886fdf322a49b7/Parser/OperatingSystem.php#L434
    def windows_version
      return if platform_version.nil?

      major_version = platform_version.split('.').first.to_i
      return if major_version < 1

      major_version < 11 ? '10' : '11'
    end

    # https://github.com/matomo-org/device-detector/blob/be1c9ef486c247dc4886668da5ed0b1c49d90ba8/Parser/Client/Browser.php#L749
    # If version from client hints report 2022 or 2022.04, then is the Iridium browser
    # https://iridiumbrowser.de/news/2022/05/16/version-2022-04-released
    def is_iridium?
      return if browser_list.nil?

      !browser_list.find do |browser|
        browser.name == 'Chromium' && %w[2021.12 2022.04 2022].include?(browser.version)
      end.nil?
    end

    def app_name_from_headers
      return if headers.nil?

      headers['http-x-requested-with'] ||
        headers['X-Requested-With'] ||
        headers['x-requested-with']
    end

    def extract_app_name
      requested_with = app_name_from_headers
      return if requested_with.nil?

      hint_app_names[requested_with]
    end

    def hint_app_names
      DeviceDetector.cache.get_or_set('hint_app_names') do
        load_hint_app_names.flatten.reduce({}, :merge)
      end
    end

    def hint_filenames
      %w[client/hints/browsers.yml client/hints/apps.yml]
    end

    def hint_filepaths
      hint_filenames.map do |filename|
        [filename.to_sym, File.join(ROOT, 'regexes', filename)]
      end
    end

    def load_hint_app_names
      hint_filepaths.map { |_, full_path| YAML.load_file(full_path) }
    end

    def extract_browser_list
      return if headers['Sec-CH-UA'].nil?

      headers['Sec-CH-UA'].split(', ').map do |component|
        name_and_version = extract_browser_name_and_version(component)
        next if name_and_version[:name].nil?

        HintBrowser.new(name_and_version[:name], name_and_version[:version])
      end.compact
    end

    def extract_browser_name_and_version(component)
      component_and_version = component.gsub('"', '').split("\;v=")
      name = name_from_known_browsers(component_and_version.first)
      browser_version = full_version&.gsub('"', '') || component_and_version.last
      { name: name, version: browser_version }
    end

    # https://github.com/matomo-org/device-detector/blob/be1c9ef486c247dc4886668da5ed0b1c49d90ba8/Parser/Client/Browser.php#L865
    def name_from_known_browsers(name)
      # https://github.com/matomo-org/device-detector/blob/be1c9ef486c247dc4886668da5ed0b1c49d90ba8/Parser/Client/Browser.php#L628
      return 'Chrome' if name == 'Google Chrome'

      available_browsers.find do |i|
        i == name ||
          i.gsub(' ', '') == name.gsub(' ', '') ||
          i == name.gsub('Browser', '') ||
          i == name.gsub(' Browser', '') ||
          i == "#{name} Browser"
      end
    end

    def extract_model
      return if headers['Sec-CH-UA-Model'].nil? || headers['Sec-CH-UA-Model'] == ''

      headers['Sec-CH-UA-Model']
    end
  end
end
