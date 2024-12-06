# frozen_string_literal: true

module Ferrum
  class Dialog
    attr_reader :message, :default_prompt

    def initialize(page, params)
      @page = page
      @message = params["message"]
      @default_prompt = params["defaultPrompt"]
    end

    #
    # Accept dialog with given text or default prompt if applicable
    #
    # @param [String, nil] prompt_text
    #
    # @example
    #   browser = Ferrum::Browser.new
    #   browser.on(:dialog) do |dialog|
    #     if dialog.match?(/bla-bla/)
    #       dialog.accept
    #     else
    #       dialog.dismiss
    #     end
    #   end
    #   browser.go_to("https://google.com")
    #
    def accept(prompt_text = nil)
      options = { accept: true }
      response = prompt_text || default_prompt
      options.merge!(promptText: response) if response
      @page.command("Page.handleJavaScriptDialog", slowmoable: true, **options)
    end

    #
    # Dismiss dialog.
    #
    # @example
    #   browser = Ferrum::Browser.new
    #   browser.on(:dialog) do |dialog|
    #     if dialog.match?(/bla-bla/)
    #       dialog.accept
    #     else
    #       dialog.dismiss
    #     end
    #   end
    #   browser.go_to("https://google.com")
    #
    def dismiss
      @page.command("Page.handleJavaScriptDialog", slowmoable: true, accept: false)
    end

    def match?(regexp)
      !!message.match(regexp)
    end
  end
end
