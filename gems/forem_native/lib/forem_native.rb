require_relative "forem_native/version"
require_relative "forem_native/builder"

# `ForemNative` provides in-process Rust acceleration (via `magnus` + `rb-sys`)
# for CPU-bound and allocation-heavy operations in Forem.
#
# In production, CI, and local development, it loads either the platform-compiled
# shared library (`forem_native/forem_native.{so,bundle}` from `Containerfile` /
# `rake forem_native:compile`) or the committed precompiled platform binary
# (`forem_native/{arm64-darwin,x86_64-darwin,x86_64-linux}/forem_native.{so,bundle}`),
# and automatically compiles via `cargo` on first load if neither is staged yet.
module ForemNative
  @native_loaded = false

  class << self
    def load_native!
      return true if @native_loaded && defined?(Native)

      # 1. If a local `cargo build --release` has already produced an artifact in `target/release`
      #    (and no precompiled or staged binary is present yet), stage it into `lib/forem_native/`.
      if !Builder.precompiled_binary_exists? && File.exist?(Builder.cargo_artifact_path)
        Builder.install_built_artifact!
      end

      # 2. Try loading an already-staged local/Containerfile build or precompiled platform binary.
      if require_candidate_binary
        @native_loaded = true
        return true
      end

      # 3. If no binary is present on disk yet (e.g. an exotic platform),
      #    compile the Rust workspace automatically via `cargo` and load it.
      if Builder.compile! && require_candidate_binary
        @native_loaded = true
        return true
      end

      raise LoadError,
            "Failed to load ForemNative Rust extension for #{RUBY_PLATFORM}. " \
            "Run `bundle exec rake forem_native:compile` or ensure `cargo` is installed."
    end

    # Returns true when the compiled Rust `magnus` extension is loaded and active.
    def available?
      @native_loaded && defined?(Native) ? true : false
    end
    alias native_available? available?
    alias native_loaded? available?

    # Counts word tokens matching `content.to_s.split(/\W+/).count`.
    def split_word_count(content)
      Native.split_word_count(content.to_s)
    end

    # Calculates article reading time in minutes matching
    # `(content.to_s.split(/\W+/).count / 275.0).ceil`.
    def calculate_reading_time(content)
      Native.calculate_reading_time(content.to_s)
    end

    private

    def require_candidate_binary
      candidates = ["forem_native/forem_native"] +
        Builder.platform_candidates.map { |dir| "forem_native/#{dir}/forem_native" }

      candidates.each do |candidate|
        require candidate
        return true if defined?(ForemNative::Native)
      rescue LoadError
        next
      end

      false
    end
  end
end

ForemNative.load_native!
