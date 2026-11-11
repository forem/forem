require "fileutils"
require "rbconfig"

module ForemNative
  # Helper for compiling the Rust workspace into a Ruby C-ABI shared library
  # (`forem_native.bundle` on macOS, `forem_native.so` on Linux) when `cargo`
  # is available, and resolving normalized platform directories (`arm64-darwin`,
  # `x86_64-darwin`, `x86_64-linux`).
  module Builder
    GEM_ROOT = File.expand_path("../..", __dir__).freeze
    MANIFEST_PATH = File.join(GEM_ROOT, "Cargo.toml").freeze
    TARGET_RELEASE_DIR = File.join(GEM_ROOT, "target", "release").freeze
    LIB_TARGET_DIR = File.join(GEM_ROOT, "lib", "forem_native").freeze

    def self.dlext
      RbConfig::CONFIG["DLEXT"] || "so"
    end

    def self.normalized_platform(platform = RUBY_PLATFORM)
      platform.to_s.sub(/darwin\d+$/, "darwin").sub(/-gnu$/, "")
    end

    def self.platform_candidates(platform = RUBY_PLATFORM)
      [platform.to_s, normalized_platform(platform)].uniq
    end

    def self.cargo_lib_filename
      case RbConfig::CONFIG["host_os"]
      when /darwin|mac os/i
        "libforem_native.dylib"
      when /mswin|mingw|cygwin/i
        "forem_native.dll"
      else
        "libforem_native.so"
      end
    end

    def self.cargo_artifact_path
      File.join(TARGET_RELEASE_DIR, cargo_lib_filename)
    end

    def self.extension_binary_path(platform_dir: nil)
      base_dir = platform_dir ? File.join(LIB_TARGET_DIR, platform_dir) : LIB_TARGET_DIR
      File.join(base_dir, "forem_native.#{dlext}")
    end

    def self.precompiled_binary_exists?(platform = RUBY_PLATFORM)
      File.exist?(extension_binary_path) ||
        platform_candidates(platform).any? { |dir| File.exist?(extension_binary_path(platform_dir: dir)) }
    end

    def self.binary_exports_symbol?(binary_path, symbol_name)
      return false unless binary_path && File.file?(binary_path)

      File.binread(binary_path).include?(symbol_name.to_s.b)
    rescue SystemCallError
      false
    end

    def self.fresh_binary_exists?(symbol_name, platform: RUBY_PLATFORM)
      binary_exports_symbol?(extension_binary_path, symbol_name) ||
        platform_candidates(platform).any? do |dir|
          binary_exports_symbol?(extension_binary_path(platform_dir: dir), symbol_name)
        end
    end

    def self.cargo_available?
      return false if ENV["FOREM_NATIVE_SKIP_BUILD"] == "1"

      system("cargo", "--version", out: File::NULL, err: File::NULL)
    end

    def self.install_built_artifact!(dest_dir = LIB_TARGET_DIR)
      return false unless File.exist?(cargo_artifact_path)

      FileUtils.mkdir_p(dest_dir)
      dest = File.join(dest_dir, "forem_native.#{dlext}")
      # Copy to a sibling temp file and rename atomically so overwriting a previously mmap'd
      # shared library on macOS ARM64 never mutates an active vnode page cache in place.
      tmp_dest = "#{dest}.tmp.#{Process.pid}.#{rand(1_000_000)}"
      FileUtils.cp(cargo_artifact_path, tmp_dest)
      File.rename(tmp_dest, dest)
      true
    ensure
      FileUtils.rm_f(tmp_dest) if tmp_dest && File.exist?(tmp_dest)
    end

    def self.compile!(dest_dir: LIB_TARGET_DIR)
      return false unless cargo_available?

      success = system("cargo", "build", "--release", "--manifest-path", MANIFEST_PATH, chdir: GEM_ROOT)
      return false unless success

      install_built_artifact!(dest_dir)
    end
  end
end
