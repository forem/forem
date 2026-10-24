require_relative "forem_native/version"
require_relative "forem_native/ruby_fallback"
require_relative "forem_native/builder"

# `ForemNative` provides in-process Rust acceleration (via `magnus` + `rb-sys`)
# for CPU-bound and allocation-heavy operations in Forem, with a zero-risk
# pure-Ruby fallback so Docker, Kamal, and Heroku deployments never require a
# Rust compiler at runtime.
module ForemNative
  @native_loaded = false
  @force_fallback = false

  class << self
    def load_native!
      return true if @native_loaded
      return false if ENV["FOREM_NATIVE_DISABLE"] == "1"

      # If `cargo build --release` has already produced an artifact in `target/release`
      # (e.g. during local dev or CI), stage it into `lib/forem_native/` before requiring.
      if !File.exist?(Builder.extension_binary_path) && File.exist?(Builder.cargo_artifact_path)
        Builder.install_built_artifact!
      end

      candidates = [
        "forem_native/#{RUBY_PLATFORM}/forem_native",
        "forem_native/forem_native",
      ]

      candidates.each do |candidate|
        require candidate
        @native_loaded = defined?(ForemNative::Native) ? true : false
        return true if @native_loaded
      rescue LoadError
        next
      end

      @native_loaded = false
    end

    # Returns true when the compiled Rust `magnus` extension is loaded and active.
    def available?
      !@force_fallback && @native_loaded && defined?(Native) ? true : false
    end
    alias native_available? available?

    # Returns true when the C-ABI shared library is loaded in the process,
    # regardless of whether `with_fallback` is temporarily active.
    def native_loaded?
      @native_loaded && defined?(Native) ? true : false
    end

    # Temporarily forces `ForemNative.available?` to return false inside the block
    # so specs can deterministically verify both the Rust path and the Ruby fallback path.
    def with_fallback
      previous = @force_fallback
      @force_fallback = true
      yield
    ensure
      @force_fallback = previous
    end

    # Counts word tokens matching `content.to_s.split(/\W+/).count`.
    def split_word_count(content)
      text = content.to_s
      if available? && defined?(Native)
        Native.split_word_count(text)
      else
        RubyFallback.split_word_count(text)
      end
    end

    # Calculates article reading time in minutes matching
    # `(content.to_s.split(/\W+/).count / 275.0).ceil`.
    def calculate_reading_time(content)
      text = content.to_s
      if available? && defined?(Native)
        Native.calculate_reading_time(text)
      else
        RubyFallback.calculate_reading_time(text)
      end
    end
  end
end

ForemNative.load_native!
