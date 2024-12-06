require 'json'
require 'easy_translate/request'

module EasyTranslate

  module TranslationTarget

    # Determine what translations are available
    # @param [String] source - The source language (optional)
    # @param [Hash] options - extra options
    # @return [Array] an array of strings representing languages
    def translations_available(target = nil, options = {})
      request = TranslationTargetRequest.new(target, options)
      raw = request.perform_raw
      JSON.parse(raw)['data']['languages'].map do |res|
        res['language']
      end
    end

    class TranslationTargetRequest < EasyTranslate::Request

      def initialize(target = nil, options = nil)
        super(options)
        @target = target
        if @options
          if replacement_api_key = @options.delete(:api_key)
            @options[:key] = replacement_api_key
          end
        end
      end

      def params
        params = super || {}
        params[:target] = @target unless @target.nil?
        params.merge! @options if @options
        params
      end

      def path
        '/language/translate/v2/languages'
      end

    end

  end

end
