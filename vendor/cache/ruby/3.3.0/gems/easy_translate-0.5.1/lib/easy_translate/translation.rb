require 'json'
require 'cgi'
require 'easy_translate/request'
require 'easy_translate/threadable'

module EasyTranslate

  module Translation
    include Threadable

    # Translate text
    # @param [String, Array] texts - A single string or set of strings to translate
    # @option options [Fixnum] :batch_size - Maximum keys per request (optional, default 100)
    # @option options [Fixnum] :concurrency - Maximum concurrent requests (optional, default 4)
    # @option options [String, Symbol] :source - The source language (optional)
    # @option options [String, Symbol] :target - The target language (required)
    # @option options [Boolean] :html - Whether or not the supplied string is HTML (optional)
    # @return [String, Array] Translated text or texts
    def translate(texts, options = {}, http_options = {})
      threaded_process(:request_translations, texts, options, http_options)
    end

    private

    # Perform a single request to translate texts
    # @param [Array] texts - Texts to translate
    # @option options [String, Symbol] :source - The source language (optional)
    # @option options [String, Symbol] :target - The target language (required)
    # @option options [Boolean] :html - Whether or not the supplied string is HTML (optional)
    # @return [String, Array] Translated text or texts
    def request_translations(texts, options = {}, http_options = {})
      request = TranslationRequest.new(texts, options, http_options)
      # Turn the response into an array of translations
      raw = request.perform_raw
      JSON.parse(raw)['data']['translations'].map do |res|
        raw_translation = res['translatedText']
        CGI.unescapeHTML(raw_translation)
      end
    end

    # A convenience class for wrapping a translation request
    class TranslationRequest < EasyTranslate::Request

      # Set the texts and options
      # @param [String, Array] texts - the text (or texts) to translate
      # @param [Hash] options - Options to override or pass along with the request
      def initialize(texts, options, http_options = {})
        options = options.dup
        self.texts = texts
        self.html = options.delete(:html)
        @source = options.delete(:from)
        @target = options.delete(:to)
        @model = options.delete(:model)
        raise ArgumentError.new('No target language provided') unless @target
        raise ArgumentError.new('Support for multiple targets dropped in V2') if @target.is_a?(Array)
        @http_options = http_options
        if options
          @options = options
          if replacement_api_key = @options.delete(:api_key)
            @options[:key] = replacement_api_key
          end
        end
      end

      # The params for this request
      # @return [Hash] the params for the request
      def params
        params          = super || {}
        params[:source] = lang(@source) unless @source.nil?
        params[:target] = lang(@target) unless @target.nil?
        params[:model]  = @model unless @model.nil?
        params[:format] = @format unless @format.nil?
        params.merge! @options if @options
        params
      end

      # The path for the request
      # @return [String] The path for the request
      def path
        '/language/translate/v2'
      end

      # The body for the request
      # @return [String] the body for the request, URL escaped
      def body
        @texts.map { |t| "q=#{CGI::escape(t)}" }.join '&'
      end

      # Whether or not this was a request for multiple texts
      # @return [Boolean]
      def multi?
        @multi
      end

      private

      # Look up a language in the table (if needed)
      def lang(orig)
        look = orig.is_a?(String) ? orig : orig.to_s
        return look if LANGUAGES[look] # shortcut iteration
        if val = LANGUAGES.detect { |k, v| v == look }
          return val.first
        end
        look
      end

      # Set the HTML attribute, if true add a format
      # @param [Boolean] b - Whether or not the text supplied iS HTML
      def html=(b)
        @format = b ? 'html' : nil
      end

      # Set the texts for this request
      # @param [String, Array] texts - The text or texts for this request
      def texts=(texts)
        if texts.is_a?(String)
          @multi = false
          @texts = [texts]
        else
          @multi = true
          @texts = texts
        end
      end

    end

  end

end
