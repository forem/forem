# frozen_string_literal: true

module Ferrum
  class Browser
    class Options
      class Chrome < Base
        DEFAULT_OPTIONS = {
          "headless" => nil,
          "disable-gpu" => nil,
          "hide-scrollbars" => nil,
          "mute-audio" => nil,
          "enable-automation" => nil,
          "disable-web-security" => nil,
          "disable-session-crashed-bubble" => nil,
          "disable-breakpad" => nil,
          "disable-sync" => nil,
          "no-first-run" => nil,
          "use-mock-keychain" => nil,
          "keep-alive-for-test" => nil,
          "disable-popup-blocking" => nil,
          "disable-extensions" => nil,
          "disable-component-extensions-with-background-pages" => nil,
          "disable-hang-monitor" => nil,
          "disable-features" => "site-per-process,IsolateOrigins,TranslateUI",
          "disable-translate" => nil,
          "disable-background-networking" => nil,
          "enable-features" => "NetworkService,NetworkServiceInProcess",
          "disable-background-timer-throttling" => nil,
          "disable-backgrounding-occluded-windows" => nil,
          "disable-client-side-phishing-detection" => nil,
          "disable-default-apps" => nil,
          "disable-dev-shm-usage" => nil,
          "disable-ipc-flooding-protection" => nil,
          "disable-prompt-on-repost" => nil,
          "disable-renderer-backgrounding" => nil,
          "disable-site-isolation-trials" => nil,
          "force-color-profile" => "srgb",
          "metrics-recording-only" => nil,
          "safebrowsing-disable-auto-update" => nil,
          "password-store" => "basic",
          "no-startup-window" => nil
          # NOTE: --no-sandbox is not needed if you properly setup a user in the container.
          # https://github.com/ebidel/lighthouse-ci/blob/master/builder/Dockerfile#L35-L40
          # "no-sandbox" => nil,
        }.freeze

        MAC_BIN_PATH = [
          "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
          "/Applications/Chromium.app/Contents/MacOS/Chromium"
        ].freeze
        LINUX_BIN_PATH = %w[chrome google-chrome google-chrome-stable google-chrome-beta
                            chromium chromium-browser google-chrome-unstable].freeze
        WINDOWS_BIN_PATH = [
          "C:/Program Files/Google/Chrome/Application/chrome.exe",
          "C:/Program Files/Google/Chrome Dev/Application/chrome.exe"
        ].freeze
        PLATFORM_PATH = {
          mac: MAC_BIN_PATH,
          windows: WINDOWS_BIN_PATH,
          linux: LINUX_BIN_PATH
        }.freeze

        def merge_required(flags, options, user_data_dir)
          flags = flags.merge("remote-debugging-port" => options.port,
                              "remote-debugging-address" => options.host,
                              # Doesn't work on MacOS, so we need to set it by CDP
                              "window-size" => options.window_size&.join(","),
                              "user-data-dir" => user_data_dir)

          if options.proxy
            flags.merge!("proxy-server" => "#{options.proxy[:host]}:#{options.proxy[:port]}")
            flags.merge!("proxy-bypass-list" => options.proxy[:bypass]) if options.proxy[:bypass]
          end

          flags
        end

        def merge_default(flags, options)
          defaults = case options.headless
                     when false
                       except("headless", "disable-gpu")
                     when "new"
                       except("headless").merge("headless" => "new")
                     end

          defaults ||= DEFAULT_OPTIONS
          defaults.merge(flags)
        end
      end
    end
  end
end
