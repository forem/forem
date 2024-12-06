# frozen_string_literal: true

require 'katex/version'
require 'execjs'
require 'erb'

# Provides a Ruby wrapper for KaTeX server-side rendering.
module Katex
  @load_context_mutex = Mutex.new
  @context = nil
  @execjs_runtime = -> { ExecJS.runtime }

  class << self
    # rubocop:disable Metrics/MethodLength,Metrics/ParameterLists

    # Renders the given math expression to HTML via katex.renderToString.
    #
    # @param math [String] The math (Latex) expression
    # @param display_mode [Boolean] Whether to render in display mode.
    # @param throw_on_error [Boolean] Whether to raise on error. If false,
    #   renders the error message instead (even in case of ParseError, unlike
    #   the native katex).
    # @param error_color [String] Error text CSS color.
    # @param render_options [Hash] Additional options for katex.renderToString.
    #   See https://github.com/Khan/KaTeX#rendering-options.
    # @return [String] HTML. If strings respond to html_safe, the result will be
    #   HTML-safe.
    # @note This method is thread-safe as long as your ExecJS runtime is
    #   thread-safe. MiniRacer is the recommended runtime.
    def render(math, display_mode: false, throw_on_error: true,
               error_color: '#cc0000', macros: {}, **render_options)
      maybe_html_safe katex_context.call(
        'katex.renderToString',
        math,
        displayMode: display_mode,
        throwOnError: throw_on_error,
        errorColor: error_color,
        macros: macros,
        **render_options
      )
    rescue ExecJS::ProgramError => e
      raise e if throw_on_error

      render_exception e, error_color
    end
    # rubocop:enable Metrics/MethodLength,Metrics/ParameterLists

    # The ExecJS runtime factory, default: `-> { ExecJS.runtime }`.
    # Set this before calling any other methods to use a different runtime.
    #
    # This proc is guaranteed to be called at most once.
    attr_accessor :execjs_runtime

    def katex_context
      @load_context_mutex.synchronize do
        @context ||= @execjs_runtime.call.compile File.read katex_js_path
      end
    end

    def katex_js_path
      File.expand_path File.join('vendor', 'katex', 'javascripts', 'katex.js'),
                       gem_path
    end

    def gem_path
      @gem_path ||=
        File.expand_path(File.join(File.dirname(__FILE__), '..'))
    end

    private

    def render_exception(exception, error_color)
      maybe_html_safe <<~HTML
        <span class='katex'>
          <span class='katex-html'>
            <span style='color: #{error_color}'>
              #{ERB::Util.h exception.message.sub(/^ParseError: /, '')}
            </span>
          </span>
        </span>
      HTML
    end

    def maybe_html_safe(html)
      if html.respond_to?(:html_safe)
        html.html_safe
      else
        html
      end
    end
  end
end

if defined?(::Rails)
  require 'katex/engine'
else
  assets_path = File.join(Katex.gem_path, 'vendor', 'katex')
  if defined?(::Sprockets)
    %w[fonts javascripts images].each do |subdirectory|
      path = File.join(assets_path, subdirectory)
      Sprockets.append_path(path) if File.directory?(path)
    end
    Sprockets.append_path(File.join(assets_path, 'sprockets', 'stylesheets'))
  elsif defined?(::Hanami)
    Hanami::Assets.sources << assets_path
  end
end
