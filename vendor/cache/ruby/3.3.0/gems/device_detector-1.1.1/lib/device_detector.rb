# frozen_string_literal: true

require 'yaml'

require 'device_detector/version'
require 'device_detector/metadata_extractor'
require 'device_detector/version_extractor'
require 'device_detector/model_extractor'
require 'device_detector/name_extractor'
require 'device_detector/memory_cache'
require 'device_detector/parser'
require 'device_detector/bot'
require 'device_detector/client'
require 'device_detector/device'
require 'device_detector/os'
require 'device_detector/browser'
require 'device_detector/client_hint'
require 'device_detector/vendor_fragment'

class DeviceDetector
  attr_reader :client_hint, :user_agent

  def initialize(user_agent, headers = nil)
    @client_hint = ClientHint.new(headers)
    utf8_user_agent = encode_user_agent_if_needed(user_agent)
    @user_agent = set_user_agent(utf8_user_agent)
  end

  # https://github.com/matomo-org/device-detector/blob/c235832dba13961ab0f71b681616baf1aa48de23/Parser/Device/AbstractDeviceParser.php#L1873
  def set_user_agent(user_agent)
    return user_agent if client_hint.model.nil?

    regex = build_regex('Android 10[.\d]*; K(?: Build/|[;)])')
    return user_agent unless user_agent =~ regex

    version = client_hint.os_version || '10'

    user_agent.gsub(regex, "Android #{version}, #{client_hint.model}")
  end

  def encode_user_agent_if_needed(user_agent)
    return if user_agent.nil?
    return user_agent if user_agent.encoding.name == 'UTF-8'

    user_agent.encode('utf-8', 'binary', undef: :replace)
  end

  def name
    return client.name if mobile_fix?

    client_hint.browser_name || client.name
  end

  def full_version
    client_hint.platform_version || client.full_version
  end

  def os_family
    return 'GNU/Linux' if linux_fix?

    client_hint.os_family || os.family || client_hint.platform
  end

  def os_name
    return 'GNU/Linux' if linux_fix?

    client_hint.os_name || os.name || client_hint.platform
  end

  def os_full_version
    return if skip_os_version?

    client_hint.os_version || os.full_version
  end

  def device_name
    return if fake_ua?

    device.name || client_hint.model || fix_for_x_music
  end

  def device_brand
    return if fake_ua?

    # Assume all devices running iOS / Mac OS are from Apple
    brand = device.brand
    brand = 'Apple' if brand.nil? && ['Apple TV', 'iOS', 'Mac'].include?(os_name)

    brand
  end

  def device_type
    t = device.type

    # Chrome on Android passes the device type based on the keyword 'Mobile'
    # If it is present the device should be a smartphone, otherwise it's a tablet
    # See https://developer.chrome.com/multidevice/user-agent#chrome_for_android_user_agent
    # Note: We do not check for browser (family) here, as there might be mobile apps using Chrome,
    # that won't have a detected browser, but can still be detected. So we check the useragent for
    # Chrome instead.
    if t.nil? && os_family == 'Android' && user_agent =~ build_regex('Chrome\/[\.0-9]*')
      if user_agent =~ build_regex('(?:Mobile|eliboM) Safari\/')
        t = 'smartphone'
      elsif user_agent =~ build_regex('(?!Mobile )Safari\/')
        t = 'tablet'
      end
    end

    # Some UA contain the fragment 'Android; Tablet;' or 'Opera Tablet', so we assume those devices
    # as tablets
    t = 'tablet' if t.nil? && android_tablet_fragment? || opera_tablet?

    # Some user agents simply contain the fragment 'Android; Mobile;', so we assume those devices
    # as smartphones
    t = 'smartphone' if t.nil? && android_mobile_fragment?

    # Android up to 3.0 was designed for smartphones only. But as 3.0,
    # which was tablet only, was published too late, there were a
    # bunch of tablets running with 2.x With 4.0 the two trees were
    # merged and it is for smartphones and tablets
    #
    # So were are expecting that all devices running Android < 2 are
    # smartphones Devices running Android 3.X are tablets. Device type
    # of Android 2.X and 4.X+ are unknown
    if t.nil? && os_name == 'Android' && os.full_version && !os.full_version.empty?
      full_version = Gem::Version.new(os.full_version)
      if full_version < VersionExtractor::MAJOR_VERSION_2
        t = 'smartphone'
      elsif full_version >= VersionExtractor::MAJOR_VERSION_3 && \
            full_version < VersionExtractor::MAJOR_VERSION_4
        t = 'tablet'
      end
    end

    # All detected feature phones running android are more likely a smartphone
    t = 'smartphone' if t == 'feature phone' && os_family == 'Android'

    # All unknown devices under running Java ME are more likely a features phones
    t = 'feature phone' if t.nil? && os_name == 'Java ME'

    # According to http://msdn.microsoft.com/en-us/library/ie/hh920767(v=vs.85).aspx
    # Internet Explorer 10 introduces the "Touch" UA string token. If this token is present at the
    # end of the UA string, the computer has touch capability, and is running Windows 8 (or later).
    # This UA string will be transmitted on a touch-enabled system running Windows 8 (RT)
    #
    # As most touch enabled devices are tablets and only a smaller part are desktops/notebooks we
    # assume that all Windows 8 touch devices are tablets.
    if t.nil? && touch_enabled? &&
       (os_name == 'Windows RT' ||
        (os_name == 'Windows' && os_full_version &&
         Gem::Version.new(os_full_version) >= VersionExtractor::MAJOR_VERSION_8))
      t = 'tablet'
    end

    # All devices running Opera TV Store are assumed to be a tv
    t = 'tv' if opera_tv_store?

    # All devices that contain Andr0id in string are assumed to be a tv
    t = 'tv' if user_agent =~ build_regex('Andr0id|Android TV')

    # All devices running Tizen TV or SmartTV are assumed to be a tv
    t = 'tv' if t.nil? && tizen_samsung_tv?

    # Devices running Kylo or Espital TV Browsers are assumed to be a TV
    t = 'tv' if t.nil? && ['Kylo', 'Espial TV Browser'].include?(name)

    # All devices containing TV fragment are assumed to be a tv
    t = 'tv' if t.nil? && user_agent =~ build_regex('\(TV;')

    has_desktop = t != 'desktop' && desktop_string? && desktop_fragment?
    t = 'desktop' if has_desktop

    # set device type to desktop for all devices running a desktop os that were not detected as
    # another device type
    return t if t || !desktop?

    'desktop'
  end

  def known?
    client.known?
  end

  def bot?
    bot.bot?
  end

  def bot_name
    bot.name
  end

  class << self
    class Configuration
      attr_accessor :max_cache_keys

      def to_hash
        {
          max_cache_keys: max_cache_keys
        }
      end
    end

    def config
      @config ||= Configuration.new
    end

    def cache
      @cache ||= MemoryCache.new(config.to_hash)
    end

    def configure
      @config = Configuration.new
      yield(config)
    end
  end

  private

  def bot
    @bot ||= Bot.new(user_agent)
  end

  def client
    @client ||= Client.new(user_agent)
  end

  def device
    @device ||= Device.new(user_agent)
  end

  def os
    @os ||= OS.new(user_agent)
  end

  # https://github.com/matomo-org/device-detector/blob/827a3fab7e38c3274c18d2f5f5bc2a78b7ef4a3a/DeviceDetector.php#L921C5-L921C5
  def fake_ua?
    os_name == 'Android' && device.brand == 'Apple'
  end

  # https://github.com/matomo-org/device-detector/blob/be1c9ef486c247dc4886668da5ed0b1c49d90ba8/Parser/Client/Browser.php#L772
  # Fix mobile browser names e.g. Chrome => Chrome Mobile
  def mobile_fix?
    client.name == "#{client_hint.browser_name} Mobile"
  end

  def linux_fix?
    client_hint.platform == 'Linux' && os.name == 'Android' && client_hint.mobile == '?0'
  end

  # Related to issue mentionned in device.rb#1562
  def fix_for_x_music
    user_agent&.include?('X-music Ⅲ') ? 'X-Music III' : nil
  end

  def skip_os_version?
    !client_hint.os_family.nil? && client_hint.os_family != os.family
  end

  def android_tablet_fragment?
    user_agent =~ build_regex('Android( [\.0-9]+)?; Tablet;')
  end

  def android_mobile_fragment?
    user_agent =~ build_regex('Android( [\.0-9]+)?; Mobile;')
  end

  def desktop_fragment?
    user_agent =~ build_regex('Desktop (x(?:32|64)|WOW64);')
  end

  def touch_enabled?
    user_agent =~ build_regex('Touch')
  end

  def opera_tv_store?
    user_agent =~ build_regex('Opera TV Store')
  end

  def opera_tablet?
    user_agent =~ build_regex('Opera Tablet')
  end

  def tizen_samsung_tv?
    user_agent =~ build_regex('SmartTV|Tizen.+ TV .+$')
  end

  def uses_mobile_browser?
    client.browser? && client.mobile_only_browser?
  end

  # This is a workaround until we support detecting mobile only browsers
  def desktop_string?
    user_agent =~ /Desktop/
  end

  def desktop?
    return false if os_name.nil? || os_name == '' || os_name == 'UNK'

    # Check for browsers available for mobile devices only
    return false if uses_mobile_browser?

    os.desktop?
  end

  def build_regex(src)
    Regexp.new('(?:^|[^A-Z0-9\_\-])(?:' + src + ')', Regexp::IGNORECASE)
  end
end
