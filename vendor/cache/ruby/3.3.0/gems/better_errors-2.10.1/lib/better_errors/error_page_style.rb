module BetterErrors
  # @private
  module ErrorPageStyle
    def self.compiled_css(for_deployment = false)
      begin
        require "sassc"
      rescue LoadError
        raise LoadError, "The `sassc` gem is required when developing the `better_errors` gem. "\
          "If you're using a release of `better_errors`, the compiled CSS is missing from the released gem"
        # If you arrived here because sassc is not in your project's Gemfile,
        # the issue here is that the release of the better_errors gem
        # is supposed to contain the compiled CSS, but that file is missing from the release.
        # So better_errors is trying to build the CSS on the fly, which requires the sassc gem.
        #
        # If you're developing the better_errors gem locally, and you're running a project
        # that does not have sassc in its bundle, run `rake style:build` in the better_errors
        # project to compile the CSS file.
      end

      style_dir = File.expand_path("style", File.dirname(__FILE__))
      style_file = "#{style_dir}/main.scss"

      engine = SassC::Engine.new(
        File.read(style_file),
        filename: style_file,
        style: for_deployment ? :compressed : :expanded,
        line_comments: !for_deployment,
        load_paths: [style_dir],
      )
      engine.render
    end

    def self.style_tag(csp_nonce)
      style_file = File.expand_path("templates/main.css", File.dirname(__FILE__))
      css = if File.exist?(style_file)
        File.open(style_file).read
      else
        compiled_css(false)
      end
      "<style type='text/css' nonce='#{csp_nonce}'>\n#{css}\n</style>"
    end
  end
end
