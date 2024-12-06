# frozen_string_literal: true

require 'diff/lcs'
require 'observer'
require 'securerandom'
require 'set'

module Solargraph
  module LanguageServer
    # The language server protocol's data provider. Hosts are responsible for
    # querying the library and processing messages. They also provide thread
    # safety for multi-threaded transports.
    #
    class Host
      autoload :Diagnoser,     'solargraph/language_server/host/diagnoser'
      autoload :Cataloger,     'solargraph/language_server/host/cataloger'
      autoload :Sources,       'solargraph/language_server/host/sources'
      autoload :Dispatch,      'solargraph/language_server/host/dispatch'
      autoload :MessageWorker, 'solargraph/language_server/host/message_worker'

      include UriHelpers
      include Logging
      include Dispatch
      include Observable

      attr_writer :client_capabilities

      def initialize
        @cancel_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @request_mutex = Mutex.new
        @cancel = []
        @buffer = String.new
        @stopped = true
        @next_request_id = 1
        @dynamic_capabilities = Set.new
        @registered_capabilities = Set.new
      end

      # Start asynchronous process handling.
      #
      # @return [void]
      def start
        return unless stopped?
        @stopped = false
        diagnoser.start
        cataloger.start
        sources.start
        message_worker.start
      end

      # Update the configuration options with the provided hash.
      #
      # @param update [Hash]
      # @return [void]
      def configure update
        return if update.nil?
        options.merge! update
        logger.level = LOG_LEVELS[options['logLevel']] || DEFAULT_LOG_LEVEL
      end

      # @return [Hash]
      def options
        @options ||= default_configuration
      end

      # Cancel the method with the specified ID.
      #
      # @param id [Integer]
      # @return [void]
      def cancel id
        @cancel_semaphore.synchronize { @cancel.push id }
      end

      # True if the host received a request to cancel the method with the
      # specified ID.
      #
      # @param id [Integer]
      # @return [Boolean]
      def cancel? id
        result = false
        @cancel_semaphore.synchronize { result = @cancel.include? id }
        result
      end

      # Delete the specified ID from the list of cancelled IDs if it exists.
      #
      # @param id [Integer]
      # @return [void]
      def clear id
        @cancel_semaphore.synchronize { @cancel.delete id }
      end

      # Called by adapter, to handle the request
      # @param request [Hash]
      # @return [void]
      def process request
        message_worker.queue(request)
      end

      # Start processing a request from the client. After the message is
      # processed, caller is responsible for sending the response.
      #
      # @param request [Hash] The contents of the message.
      # @return [Solargraph::LanguageServer::Message::Base] The message handler.
      def receive request
        if request['method']
          logger.info "Server received #{request['method']}"
          logger.debug request
          message = Message.select(request['method']).new(self, request)
          begin
            message.process
          rescue StandardError => e
            logger.warn "Error processing request: [#{e.class}] #{e.message}"
            logger.warn e.backtrace.join("\n")
            message.set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, "[#{e.class}] #{e.message}"
          end
          message
        elsif request['id']
          if requests[request['id']]
            requests[request['id']].process(request['result'])
            requests.delete request['id']
          else
            logger.warn "Discarding client response to unrecognized message #{request['id']}"
            nil
          end
        else
          logger.warn "Invalid message received."
          logger.debug request
        end
      end

      # Respond to a notification that files were created in the workspace.
      # The libraries will determine whether the files should be merged; see
      # Solargraph::Library#create_from_disk.
      #
      # @param uris [Array<String>] The URIs of the files.
      # @return [Boolean] True if at least one library accepted at least one file.
      def create *uris
        filenames = uris.map { |uri| uri_to_file(uri) }
        result = false
        libraries.each do |lib|
          result = true if lib.create_from_disk(*filenames)
        end
        uris.each do |uri|
          diagnoser.schedule uri if open?(uri)
        end
        result
      end

      # Delete the specified files from the library.
      #
      # @param uris [Array<String>] The file uris.
      # @return [void]
      def delete *uris
        filenames = uris.map { |uri| uri_to_file(uri) }
        libraries.each do |lib|
          lib.delete(*filenames)
        end
        uris.each do |uri|
          send_notification "textDocument/publishDiagnostics", {
            uri: uri,
            diagnostics: []
          }
        end
      end

      # Open the specified file in the library.
      #
      # @param uri [String] The file uri.
      # @param text [String] The contents of the file.
      # @param version [Integer] A version number.
      # @return [void]
      def open uri, text, version
        src = sources.open(uri, text, version)
        libraries.each do |lib|
          lib.merge src
        end
        diagnoser.schedule uri
      end

      # @param uri [String]
      # @return [void]
      def open_from_disk uri
        sources.open_from_disk(uri)
        diagnoser.schedule uri
      end

      # True if the specified file is currently open in the library.
      #
      # @param uri [String]
      # @return [Boolean]
      def open? uri
        sources.include? uri
      end

      # Close the file specified by the URI.
      #
      # @param uri [String]
      # @return [void]
      def close uri
        logger.info "Closing #{uri}"
        sources.close uri
        diagnoser.schedule uri
      end

      # @param uri [String]
      # @return [void]
      def diagnose uri
        if sources.include?(uri)
          library = library_for(uri)
          if library.mapped? && library.synchronized?
            logger.info "Diagnosing #{uri}"
            begin
              results = library.diagnose uri_to_file(uri)
              send_notification "textDocument/publishDiagnostics", {
                uri: uri,
                diagnostics: results
              }
            rescue DiagnosticsError => e
              logger.warn "Error in diagnostics: #{e.message}"
              options['diagnostics'] = false
              send_notification 'window/showMessage', {
                type: LanguageServer::MessageTypes::ERROR,
                message: "Error in diagnostics: #{e.message}"
              }
            rescue FileNotFoundError => e
              # @todo This appears to happen when an external file is open and
              #   scheduled for diagnosis, but the file was closed (i.e., the
              #   editor moved to a different file) before diagnosis started
              logger.warn "Unable to diagnose #{uri} : #{e.message}"
              send_notification 'textDocument/publishDiagnostics', {
                uri: uri,
                diagnostics: []
              }
            end
          else
            logger.info "Deferring diagnosis of #{uri}"
            diagnoser.schedule uri
          end
        else
          send_notification 'textDocument/publishDiagnostics', {
            uri: uri,
            diagnostics: []
          }
        end
      end

      # Update a document from the parameters of a textDocument/didChange
      # method.
      #
      # @param params [Hash]
      # @return [void]
      def change params
        updater = generate_updater(params)
        sources.async_update params['textDocument']['uri'], updater
        diagnoser.schedule params['textDocument']['uri']
      end

      # Queue a message to be sent to the client.
      #
      # @param message [String] The message to send.
      # @return [void]
      def queue message
        @buffer_semaphore.synchronize { @buffer += message }
        changed
        notify_observers
      end

      # Clear the message buffer and return the most recent data.
      #
      # @return [String] The most recent data or an empty string.
      def flush
        tmp = ''
        @buffer_semaphore.synchronize do
          tmp = @buffer.clone
          @buffer.clear
        end
        tmp
      end

      # Prepare a library for the specified directory.
      #
      # @param directory [String]
      # @param name [String, nil]
      # @return [void]
      def prepare directory, name = nil
        # No need to create a library without a directory. The generic library
        # will handle it.
        return if directory.nil?
        logger.info "Preparing library for #{directory}"
        path = ''
        path = normalize_separators(directory) unless directory.nil?
        begin
          lib = Solargraph::Library.load(path, name)
          libraries.push lib
          async_library_map lib
        rescue WorkspaceTooLargeError => e
          send_notification 'window/showMessage', {
            'type' => Solargraph::LanguageServer::MessageTypes::WARNING,
            'message' => e.message
          }
        end
      end

      # Prepare multiple folders.
      #
      # @param array [Array<Hash{String => String}>]
      # @return [void]
      def prepare_folders array
        return if array.nil?
        array.each do |folder|
          prepare uri_to_file(folder['uri']), folder['name']
        end
      end

      # Remove a directory.
      #
      # @param directory [String]
      # @return [void]
      def remove directory
        logger.info "Removing library for #{directory}"
        # @param lib [Library]
        libraries.delete_if do |lib|
          next false if lib.workspace.directory != directory
          true
        end
      end

      # @param array [Array<Hash>]
      # @return [void]
      def remove_folders array
        array.each do |folder|
          remove uri_to_file(folder['uri'])
        end
      end

      # @return [Array<String>]
      def folders
        libraries.map { |lib| lib.workspace.directory }
      end

      # Send a notification to the client.
      #
      # @param method [String] The message method
      # @param params [Hash] The method parameters
      # @return [void]
      def send_notification method, params
        response = {
          jsonrpc: "2.0",
          method: method,
          params: params
        }
        json = response.to_json
        envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
        queue envelope
        logger.info "Server sent #{method}"
        logger.debug params
      end

      # Send a request to the client and execute the provided block to process
      # the response. If an ID is not provided, the host will use an auto-
      # incrementing integer.
      #
      # @param method [String] The message method
      # @param params [Hash] The method parameters
      # @param block [Proc] The block that processes the response
      # @yieldparam [Hash] The result sent by the client
      # @return [void]
      def send_request method, params, &block
        @request_mutex.synchronize do
          message = {
            jsonrpc: "2.0",
            method: method,
            params: params,
            id: @next_request_id
          }
          json = message.to_json
          requests[@next_request_id] = Request.new(@next_request_id, &block)
          envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
          queue envelope
          @next_request_id += 1
          logger.info "Server sent #{method}"
          logger.debug params
        end
      end

      # Register the methods as capabilities with the client.
      # This method will avoid duplicating registrations and ignore methods
      # that were not flagged for dynamic registration by the client.
      #
      # @param methods [Array<String>] The methods to register
      # @return [void]
      def register_capabilities methods
        logger.debug "Registering capabilities: #{methods}"
        registrations = methods.select { |m| can_register?(m) and !registered?(m) }.map do |m|
          @registered_capabilities.add m
          {
            id: m,
            method: m,
            registerOptions: dynamic_capability_options[m]
          }
        end
        return if registrations.empty?
        send_request 'client/registerCapability', { registrations: registrations }
      end

      # Unregister the methods with the client.
      # This method will avoid duplicating unregistrations and ignore methods
      # that were not flagged for dynamic registration by the client.
      #
      # @param methods [Array<String>] The methods to unregister
      # @return [void]
      def unregister_capabilities methods
        logger.debug "Unregistering capabilities: #{methods}"
        unregisterations = methods.select{|m| registered?(m)}.map{ |m|
          @registered_capabilities.delete m
          {
            id: m,
            method: m
          }
        }
        return if unregisterations.empty?
        send_request 'client/unregisterCapability', { unregisterations: unregisterations }
      end

      # Flag a method as available for dynamic registration.
      #
      # @param method [String] The method name, e.g., 'textDocument/completion'
      # @return [void]
      def allow_registration method
        @dynamic_capabilities.add method
      end

      # True if the specified LSP method can be dynamically registered.
      #
      # @param method [String]
      # @return [Boolean]
      def can_register? method
        @dynamic_capabilities.include?(method)
      end

      # True if the specified method has been registered.
      #
      # @param method [String] The method name, e.g., 'textDocument/completion'
      # @return [Boolean]
      def registered? method
        @registered_capabilities.include?(method)
      end

      def synchronizing?
        !libraries.all?(&:synchronized?)
      end

      # @return [void]
      def stop
        return if @stopped
        @stopped = true
        message_worker.stop
        cataloger.stop
        diagnoser.stop
        sources.stop
        changed
        notify_observers
      end

      def stopped?
        @stopped
      end

      # Locate multiple pins that match a completion item. The first match is
      # based on the corresponding location in a library source if available.
      # Subsequent matches are based on path.
      #
      # @param params [Hash] A hash representation of a completion item
      # @return [Array<Pin::Base>]
      def locate_pins params
        return [] unless params['data'] && params['data']['uri']
        library = library_for(params['data']['uri'])
        result = []
        if params['data']['location']
          location = Location.new(
            params['data']['location']['filename'],
            Range.from_to(
              params['data']['location']['range']['start']['line'],
              params['data']['location']['range']['start']['character'],
              params['data']['location']['range']['end']['line'],
              params['data']['location']['range']['end']['character']
            )
          )
          result.concat library.locate_pins(location).select{ |pin| pin.name == params['label'] }
        end
        if params['data']['path']
          result.concat library.path_pins(params['data']['path'])
        end
        # Selecting by both location and path can result in duplicate pins
        result.uniq { |p| [p.path, p.location] }
      end

      # @param uri [String]
      # @return [String]
      def read_text uri
        library = library_for(uri)
        filename = uri_to_file(uri)
        library.read_text(filename)
      end

      def formatter_config uri
        library = library_for(uri)
        library.workspace.config.formatter
      end

      # @param uri [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Solargraph::SourceMap::Completion]
      def completions_at uri, line, column
        library = library_for(uri)
        library.completions_at uri_to_file(uri), line, column
      end

      # @return [Bool] if has pending completion request
      def has_pending_completions?
        message_worker.messages.reverse_each.any? { |req| req['method'] == 'textDocument/completion' }
      end

      # @param uri [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Array<Solargraph::Pin::Base>]
      def definitions_at uri, line, column
        library = library_for(uri)
        library.definitions_at(uri_to_file(uri), line, column)
      end

      # @param uri [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Array<Solargraph::Pin::Base>]
      def signatures_at uri, line, column
        library = library_for(uri)
        library.signatures_at(uri_to_file(uri), line, column)
      end

      # @param uri [String]
      # @param line [Integer]
      # @param column [Integer]
      # @param strip [Boolean] Strip special characters from variable names
      # @param only [Boolean] If true, search current file only
      # @return [Array<Solargraph::Range>]
      def references_from uri, line, column, strip: true, only: false
        library = library_for(uri)
        library.references_from(uri_to_file(uri), line, column, strip: strip, only: only)
      end

      # @param query [String]
      # @return [Array<Solargraph::Pin::Base>]
      def query_symbols query
        result = []
        (libraries + [generic_library]).each { |lib| result.concat lib.query_symbols(query) }
        result.uniq
      end

      # @param query [String]
      # @return [Array<String>]
      def search query
        result = []
        libraries.each { |lib| result.concat lib.search(query) }
        result
      end

      # @param query [String]
      # @return [Array]
      def document query
        result = []
        libraries.each { |lib| result.concat lib.document(query) }
        result
      end

      # @param uri [String]
      # @return [Array<Solargraph::Pin::Base>]
      def document_symbols uri
        library = library_for(uri)
        # At this level, document symbols should be unique; e.g., a
        # module_function method should return the location for Module.method
        # or Module#method, but not both.
        library.document_symbols(uri_to_file(uri)).uniq(&:location)
      end

      # Send a notification to the client.
      #
      # @param text [String]
      # @param type [Integer] A MessageType constant
      # @return [void]
      def show_message text, type = LanguageServer::MessageTypes::INFO
        send_notification 'window/showMessage', {
          type: type,
          message: text
        }
      end

      # Send a notification with optional responses.
      #
      # @param text [String]
      # @param type [Integer] A MessageType constant
      # @param actions [Array<String>] Response options for the client
      # @param block The block that processes the response
      # @yieldparam [String] The action received from the client
      # @return [void]
      def show_message_request text, type, actions, &block
        send_request 'window/showMessageRequest', {
          type: type,
          message: text,
          actions: actions
        }, &block
      end

      # Get a list of IDs for server requests that are waiting for responses
      # from the client.
      #
      # @return [Array<Integer>]
      def pending_requests
        requests.keys
      end

      # @return [Hash{String => Object}]
      def default_configuration
        {
          'completion' => true,
          'hover' => true,
          'symbols' => true,
          'definitions' => true,
          'rename' => true,
          'references' => true,
          'autoformat' => false,
          'diagnostics' => false,
          'formatting' => false,
          'folding' => true,
          'highlights' => true,
          'logLevel' => 'warn'
        }
      end

      # @param uri [String]
      # @return [Array<Range>]
      def folding_ranges uri
        sources.find(uri).folding_ranges
      end

      # @return [void]
      def catalog
        return unless libraries.all?(&:mapped?)
        libraries.each(&:catalog)
      end

      def client_capabilities
        @client_capabilities ||= {}
      end

      private

      # @return [MessageWorker]
      def message_worker
        @message_worker ||= MessageWorker.new(self)
      end

      # @return [Diagnoser]
      def diagnoser
        @diagnoser ||= Diagnoser.new(self)
      end

      # @return [Cataloger]
      def cataloger
        @cataloger ||= Cataloger.new(self)
      end

      # A hash of client requests by ID. The host uses this to keep track of
      # pending responses.
      #
      # @return [Hash{Integer => Hash}]
      def requests
        @requests ||= {}
      end

      # @param path [String]
      # @return [String]
      def normalize_separators path
        return path if File::ALT_SEPARATOR.nil?
        path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
      end

      # @param params [Hash]
      # @return [Source::Updater]
      def generate_updater params
        changes = []
        params['contentChanges'].each do |recvd|
          chng = check_diff(params['textDocument']['uri'], recvd)
          changes.push Solargraph::Source::Change.new(
            (chng['range'].nil? ?
              nil :
              Solargraph::Range.from_to(chng['range']['start']['line'], chng['range']['start']['character'], chng['range']['end']['line'], chng['range']['end']['character'])
            ),
            chng['text']
          )
        end
        Solargraph::Source::Updater.new(
          uri_to_file(params['textDocument']['uri']),
          params['textDocument']['version'],
          changes
        )
      end

      # @param uri [String]
      # @param change [Hash]
      # @return [Hash]
      def check_diff uri, change
        return change if change['range']
        source = sources.find(uri)
        return change if source.code.length + 1 != change['text'].length
        diffs = Diff::LCS.diff(source.code, change['text'])
        return change if diffs.length.zero? || diffs.length > 1 || diffs.first.length > 1
        # @type [Diff::LCS::Change]
        diff = diffs.first.first
        return change unless diff.adding? && ['.', ':', '(', ',', ' '].include?(diff.element)
        position = Solargraph::Position.from_offset(source.code, diff.position)
        {
          'range' => {
            'start' => {
              'line' => position.line,
              'character' => position.character
            },
            'end' => {
              'line' => position.line,
              'character' => position.character
            }
          },
          'text' => diff.element
        }
      rescue Solargraph::FileNotFoundError
        change
      end

      # @return [Hash]
      def dynamic_capability_options
        @dynamic_capability_options ||= {
          # textDocumentSync: 2, # @todo What should this be?
          'textDocument/completion' => {
            resolveProvider: true,
            triggerCharacters: ['.', ':', '@']
          },
          # hoverProvider: true,
          # definitionProvider: true,
          'textDocument/signatureHelp' => {
            triggerCharacters: ['(', ',', ' ']
          },
          # documentFormattingProvider: true,
          'textDocument/onTypeFormatting' => {
            firstTriggerCharacter: '{',
            moreTriggerCharacter: ['(']
          },
          # documentSymbolProvider: true,
          # workspaceSymbolProvider: true,
          # workspace: {
            # workspaceFolders: {
              # supported: true,
              # changeNotifications: true
            # }
          # }
          'textDocument/definition' => {
            definitionProvider: true
          },
          'textDocument/references' => {
            referencesProvider: true
          },
          'textDocument/rename' => {
            renameProvider: prepare_rename? ? { prepareProvider: true } : true
          },
          'textDocument/documentSymbol' => {
            documentSymbolProvider: true
          },
          'workspace/symbol' => {
            workspaceSymbolProvider: true
          },
          'textDocument/formatting' => {
            formattingProvider: true
          },
          'textDocument/foldingRange' => {
            foldingRangeProvider: true
          },
          'textDocument/codeAction' => {
            codeActionProvider: true
          },
          'textDocument/documentHighlight' => {
            documentHighlightProvider: true
          }
        }
      end

      def prepare_rename?
        client_capabilities['rename'] && client_capabilities['rename']['prepareSupport']
      end

      def client_supports_progress?
        client_capabilities['window'] && client_capabilities['window']['workDoneProgress']
      end

      # @param library [Library]
      # @return [void]
      def async_library_map library
        return if library.mapped?
        Thread.new do
          if client_supports_progress?
            uuid = SecureRandom.uuid
            send_request 'window/workDoneProgress/create', {
              token: uuid
            } do |response|
              do_async_library_map library, response.nil? ? uuid : nil
            end
          else
            do_async_library_map library
          end
        end
      end

      def do_async_library_map library, uuid = nil
        total = library.workspace.sources.length
        if uuid
          send_notification '$/progress', {
            token: uuid,
            value: {
              kind: 'begin',
              title: "Mapping workspace",
              message: "0/#{total} files",
              cancellable: false,
              percentage: 0
            }
          }
        end
        pct = 0
        mod = 10
        while library.next_map
          next unless uuid
          cur = ((library.source_map_hash.keys.length.to_f / total.to_f) * 100).to_i
          if cur > pct && cur % mod == 0
            pct = cur
            send_notification '$/progress', {
              token: uuid,
              value: {
                kind: 'report',
                cancellable: false,
                message: "#{library.source_map_hash.keys.length}/#{total} files",
                percentage: pct
              }
            }
          end
        end
        if uuid
          send_notification '$/progress', {
            token: uuid,
            value: {
              kind: 'end',
              message: 'Mapping complete'
            }
          }
        end
      end
    end
  end
end
