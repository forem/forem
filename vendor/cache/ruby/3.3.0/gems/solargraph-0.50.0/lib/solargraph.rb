# frozen_string_literal: true

Encoding.default_external = 'UTF-8'

require 'solargraph/version'

# The top-level namespace for the Solargraph code mapping, documentation,
# static analysis, and language server libraries.
#
module Solargraph
  class InvalidOffsetError         < RangeError;    end
  class DiagnosticsError           < RuntimeError;  end
  class FileNotFoundError          < RuntimeError;  end
  class SourceNotAvailableError    < StandardError; end
  class ComplexTypeError           < StandardError; end
  class WorkspaceTooLargeError     < RuntimeError;  end
  class BundleNotFoundError        < StandardError; end
  class InvalidRubocopVersionError < RuntimeError;  end

  autoload :Position,         'solargraph/position'
  autoload :Range,            'solargraph/range'
  autoload :Location,         'solargraph/location'
  autoload :Shell,            'solargraph/shell'
  autoload :Source,           'solargraph/source'
  autoload :SourceMap,        'solargraph/source_map'
  autoload :ApiMap,           'solargraph/api_map'
  autoload :YardMap,          'solargraph/yard_map'
  autoload :Pin,              'solargraph/pin'
  autoload :ServerMethods,    'solargraph/server_methods'
  autoload :LanguageServer,   'solargraph/language_server'
  autoload :Workspace,        'solargraph/workspace'
  autoload :Page,             'solargraph/page'
  autoload :Library,          'solargraph/library'
  autoload :Diagnostics,      'solargraph/diagnostics'
  autoload :ComplexType,      'solargraph/complex_type'
  autoload :Bench,            'solargraph/bench'
  autoload :Logging,          'solargraph/logging'
  autoload :TypeChecker,      'solargraph/type_checker'
  autoload :Environ,          'solargraph/environ'
  autoload :Convention,       'solargraph/convention'
  autoload :Documentor,       'solargraph/documentor'
  autoload :Parser,           'solargraph/parser'
  autoload :RbsMap,           'solargraph/rbs_map'
  autoload :Cache,            'solargraph/cache'

  dir = File.dirname(__FILE__)
  YARD_EXTENSION_FILE = File.join(dir, 'yard-solargraph.rb')
  VIEWS_PATH = File.join(dir, 'solargraph', 'views')

  # A convenience method for Solargraph::Logging.logger.
  #
  # @return [Logger]
  def self.logger
    Solargraph::Logging.logger
  end

  # A helper method that runs Bundler.with_unbundled_env or falls back to
  # Bundler.with_clean_env for earlier versions of Bundler.
  #
  # @return [void]
  def self.with_clean_env &block
    meth = if Bundler.respond_to?(:with_original_env)
      :with_original_env
    else
      :with_clean_env
    end
    Bundler.send meth, &block
  end
end
