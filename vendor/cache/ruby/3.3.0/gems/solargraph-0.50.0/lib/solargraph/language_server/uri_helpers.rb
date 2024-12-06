# frozen_string_literal: true

require 'cgi'

module Solargraph
  module LanguageServer
    # Methods to handle conversions between file URIs and paths.
    #
    module UriHelpers
      module_function

      # Convert a file URI to a path.
      #
      # @param uri [String]
      # @return [String]
      def uri_to_file uri
        decode(uri).sub(/^file\:(?:\/\/)?/, '').sub(/^\/([a-z]\:)/i, '\1')
      end

      # Convert a file path to a URI.
      #
      # @param file [String]
      # @return [String]
      def file_to_uri file
        "file://#{encode(file.gsub(/^([a-z]\:)/i, '/\1'))}"
      end

      # Encode text to be used as a URI path component in LSP.
      #
      # @param text [String]
      # @return [String]
      def encode text
        CGI.escape(text)
           .gsub('%3A', ':')
           .gsub('%5C', '\\')
           .gsub('%2F', '/')
           .gsub('+', '%20')
      end

      # Decode text from a URI path component in LSP.
      #
      # @param text [String]
      # @return [String]
      def decode text
        CGI.unescape(text)
      end
    end
  end
end
