# frozen_string_literal: true

require_relative 'severity'

#
# This code is based on https://github.com/standardrb/standard.
#
# Copyright (c) 2023 Test Double, Inc.
#
# The MIT License (MIT)
#
# https://github.com/standardrb/standard/blob/main/LICENSE.txt
#
module RuboCop
  module LSP
    # Routes for Language Server Protocol of RuboCop.
    # @api private
    class Routes
      def self.handle(name, &block)
        define_method(:"handle_#{name}", &block)
      end

      private_class_method :handle

      def initialize(server)
        @server = server

        @text_cache = {}
      end

      def for(name)
        name = "handle_#{name}"
        return unless respond_to?(name)

        method(name)
      end

      handle 'initialize' do |request|
        initialization_options = extract_initialization_options_from(request)

        @server.configure(initialization_options)

        @server.write(
          id: request[:id],
          result: LanguageServer::Protocol::Interface::InitializeResult.new(
            capabilities: LanguageServer::Protocol::Interface::ServerCapabilities.new(
              document_formatting_provider: true,
              diagnostic_provider: LanguageServer::Protocol::Interface::DiagnosticOptions.new(
                inter_file_dependencies: false,
                workspace_diagnostics: false
              ),
              text_document_sync: LanguageServer::Protocol::Interface::TextDocumentSyncOptions.new(
                change: LanguageServer::Protocol::Constant::TextDocumentSyncKind::FULL,
                open_close: true
              )
            )
          )
        )
      end

      handle 'initialized' do |_request|
        version = RuboCop::Version::STRING

        Logger.log("RuboCop #{version} language server initialized, PID #{Process.pid}")
      end

      handle 'shutdown' do |request|
        Logger.log('Client asked to shutdown RuboCop language server.')
        @server.stop do
          @server.write(id: request[:id], result: nil)
          Logger.log('Exiting...')
        end
      end

      handle 'textDocument/diagnostic' do |request|
        # no-op, diagnostics are handled in textDocument/didChange
      end

      handle 'textDocument/didChange' do |request|
        params = request[:params]
        result = diagnostic(params[:textDocument][:uri], params[:contentChanges][0][:text])
        @server.write(result)
      end

      handle 'textDocument/didOpen' do |request|
        doc = request[:params][:textDocument]
        result = diagnostic(doc[:uri], doc[:text])
        @server.write(result)
      end

      handle 'textDocument/didClose' do |request|
        @text_cache.delete(request.dig(:params, :textDocument, :uri))
      end

      handle 'textDocument/formatting' do |request|
        uri = request[:params][:textDocument][:uri]
        @server.write(id: request[:id], result: format_file(uri))
      end

      handle 'workspace/didChangeConfiguration' do |_request|
        Logger.log('Ignoring workspace/didChangeConfiguration')
      end

      handle 'workspace/didChangeWatchedFiles' do |request|
        changed = request[:params][:changes].any? do |change|
          change[:uri].end_with?(RuboCop::ConfigFinder::DOTFILE)
        end

        if changed
          Logger.log('Configuration file changed; restart required')
          @server.stop
        end
      end

      handle 'workspace/executeCommand' do |request|
        case (command = request[:params][:command])
        when 'rubocop.formatAutocorrects'
          label = 'Format with RuboCop autocorrects'
        when 'rubocop.formatAutocorrectsAll'
          label = 'Format all with RuboCop autocorrects'
        else
          handle_unsupported_method(request, command)
          return
        end

        uri = request[:params][:arguments][0][:uri]
        @server.write(
          id: request[:id],
          method: 'workspace/applyEdit',
          params: {
            label: label,
            edit: {
              changes: {
                uri => format_file(uri, command: command)
              }
            }
          }
        )
      end

      handle 'textDocument/willSave' do |_request|
        # Nothing to do
      end

      handle 'textDocument/didSave' do |_request|
        # Nothing to do
      end

      handle '$/cancelRequest' do |_request|
        # Can't cancel anything because single-threaded
      end

      handle '$/setTrace' do |_request|
        # No-op, we log everything
      end

      def handle_unsupported_method(request, method = request[:method])
        @server.write(
          id: request[:id],
          error: LanguageServer::Protocol::Interface::ResponseError.new(
            code: LanguageServer::Protocol::Constant::ErrorCodes::METHOD_NOT_FOUND,
            message: "Unsupported Method: #{method}"
          )
        )
        Logger.log("Unsupported Method: #{method}")
      end

      def handle_method_missing(request)
        return unless request.key?(:id)

        @server.write(id: request[:id], result: nil)
      end

      private

      def extract_initialization_options_from(request)
        safe_autocorrect = request.dig(:params, :initializationOptions, :safeAutocorrect)

        {
          safe_autocorrect: safe_autocorrect.nil? || safe_autocorrect == true,
          lint_mode: request.dig(:params, :initializationOptions, :lintMode) == true,
          layout_mode: request.dig(:params, :initializationOptions, :layoutMode) == true
        }
      end

      def format_file(file_uri, command: nil)
        unless (text = @text_cache[file_uri])
          Logger.log("Format request arrived before text synchronized; skipping: `#{file_uri}'")

          return []
        end

        new_text = @server.format(remove_file_protocol_from(file_uri), text, command: command)

        return [] if new_text == text

        [
          newText: new_text,
          range: {
            start: { line: 0, character: 0 },
            end: { line: text.count("\n") + 1, character: 0 }
          }
        ]
      end

      def diagnostic(file_uri, text)
        @text_cache[file_uri] = text
        offenses = @server.offenses(remove_file_protocol_from(file_uri), text)
        diagnostics = offenses.map { |offense| to_diagnostic(offense) }

        {
          method: 'textDocument/publishDiagnostics',
          params: {
            uri: file_uri,
            diagnostics: diagnostics
          }
        }
      end

      def remove_file_protocol_from(uri)
        uri.delete_prefix('file://')
      end

      def to_diagnostic(offense)
        code = offense[:cop_name]
        message = offense[:message]
        loc = offense[:location]
        rubocop_severity = offense[:severity]
        severity = Severity.find_by(rubocop_severity)

        {
          code: code, message: message, range: to_range(loc), severity: severity, source: 'rubocop'
        }
      end

      def to_range(location)
        {
          start: { character: location[:start_column] - 1, line: location[:start_line] - 1 },
          end: { character: location[:last_column] - 1, line: location[:last_line] - 1 }
        }
      end
    end
  end
end
