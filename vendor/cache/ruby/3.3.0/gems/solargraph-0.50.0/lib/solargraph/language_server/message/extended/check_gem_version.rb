# frozen_string_literal: true

require 'rubygems'

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Check if a more recent version of the Solargraph gem is available.
        # Notify the client when an update exists. If the `verbose` parameter
        # is true, notify the client when the gem is up to date.
        #
        class CheckGemVersion < Base
          def self.fetcher
            @fetcher ||= Gem::SpecFetcher.new
          end

          def self.fetcher= obj
            @fetcher = obj
          end

          GEM_ZERO = Gem::Version.new('0.0.0')

          def initialize host, request, current: Gem::Version.new(Solargraph::VERSION), available: nil
            super(host, request)
            @current = current
            @available = available
          end

          def process
            if available > GEM_ZERO
              if available > current
                host.show_message_request "Solargraph gem version #{available} is available. (Current version: #{current})",
                                          LanguageServer::MessageTypes::INFO,
                                          ['Update now'] do |result|
                                            next unless result == 'Update now'
                                            cmd = if host.options['useBundler']
                                              'bundle update solargraph'
                                            else
                                              'gem update solargraph'
                                            end
                                            o, s = Open3.capture2(cmd)
                                            if s == 0
                                              host.show_message 'Successfully updated the Solargraph gem.', LanguageServer::MessageTypes::INFO
                                              host.send_notification '$/solargraph/restart', {}
                                            else
                                              host.show_message 'An error occurred while updating the gem.', LanguageServer::MessageTypes::ERROR
                                            end
                                          end
              elsif params['verbose']
                host.show_message "The Solargraph gem is up to date (version #{Solargraph::VERSION})."
              end
            elsif fetched?
              Solargraph::Logging.logger.warn error
              host.show_message(error, MessageTypes::ERROR) if params['verbose']
            end
            set_result({
              installed: current,
              available: available
            })
          end

          private

          # @return [Gem::Version]
          attr_reader :current

          # @return [Gem::Version]
          def available
            if !@available && !@fetched
              @fetched = true
              begin
                @available ||= begin
                  tuple = CheckGemVersion.fetcher.search_for_dependency(Gem::Dependency.new('solargraph')).flatten.first
                  if tuple.nil?
                    @error = 'An error occurred fetching the gem data'
                    GEM_ZERO
                  else
                    tuple.version
                  end
                end
              rescue Errno::EADDRNOTAVAIL => e
                @error = "Unable to connect to gem source: #{e.message}"
                GEM_ZERO
              end
            end
            @available
          end

          def fetched?
            @fetched ||= false
          end

          # @return [String, nil]
          attr_reader :error
        end
      end
    end
  end
end
