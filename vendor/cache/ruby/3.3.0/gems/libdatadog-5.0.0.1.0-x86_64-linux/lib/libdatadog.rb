# frozen_string_literal: true

require_relative "libdatadog/version"

module Libdatadog
  # This should only be used for debugging/logging
  def self.available_binaries
    File.directory?(vendor_directory) ? (Dir.entries(vendor_directory) - [".", ".."]) : []
  end

  def self.pkgconfig_folder(pkgconfig_file_name = "datadog_profiling_with_rpath.pc")
    current_platform = Gem::Platform.local.to_s

    if RbConfig::CONFIG["arch"].include?("-musl") && !current_platform.include?("-musl")
      # Fix/workaround for https://github.com/DataDog/dd-trace-rb/issues/2222
      #
      # Old versions of rubygems (for instance 3.0.3) don't properly detect alternative libc implementations on Linux;
      # in particular for our case, they don't detect musl. (For reference, Rubies older than 2.7 may have shipped with
      # an affected version of rubygems).
      # In such cases, we fall back to use RbConfig::CONFIG['arch'] instead.
      #
      # Why not use RbConfig::CONFIG['arch'] always? Because Gem::Platform.local.to_s does some normalization we want
      # in other situations -- for instance, it turns `x86_64-linux-gnu` to `x86_64-linux`. So for now we only add this
      # workaround in a specific situation where we actually know it is wrong.
      #
      # See also https://github.com/rubygems/rubygems/pull/2922 and https://github.com/rubygems/rubygems/pull/4082

      current_platform = RbConfig::CONFIG["arch"]
    end

    return unless available_binaries.include?(current_platform)

    pkgconfig_file = Dir.glob("#{vendor_directory}/#{current_platform}/**/#{pkgconfig_file_name}").first

    return unless pkgconfig_file

    File.absolute_path(File.dirname(pkgconfig_file))
  end

  private_class_method def self.vendor_directory
    ENV["LIBDATADOG_VENDOR_OVERRIDE"] || "#{__dir__}/../vendor/libdatadog-#{Libdatadog::LIB_VERSION}/"
  end
end
