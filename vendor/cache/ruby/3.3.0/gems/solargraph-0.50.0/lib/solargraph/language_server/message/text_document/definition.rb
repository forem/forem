# frozen_string_literal: true

module Solargraph::LanguageServer::Message::TextDocument
  class Definition < Base
    def process
      @line = params['position']['line']
      @column = params['position']['character']
      set_result(code_location || require_location || [])
    end

    private

    def code_location
      suggestions = host.definitions_at(params['textDocument']['uri'], @line, @column)
      return nil if suggestions.empty?
      suggestions.reject { |pin| pin.location.nil? || pin.location.filename.nil? }.map do |pin|
        {
          uri: file_to_uri(pin.location.filename),
          range: pin.location.range.to_hash
        }
      end
    end

    def require_location
      # @todo Terrible hack
      lib = host.library_for(params['textDocument']['uri'])
      rloc = Solargraph::Location.new(uri_to_file(params['textDocument']['uri']), Solargraph::Range.from_to(@line, @column, @line, @column))
      dloc = lib.locate_ref(rloc)
      return nil if dloc.nil?
      [
        {
          uri: file_to_uri(dloc.filename),
          range: dloc.range.to_hash
        }
      ]
    end
  end
end
