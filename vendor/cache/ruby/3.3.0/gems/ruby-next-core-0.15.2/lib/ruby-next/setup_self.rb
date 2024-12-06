# frozen_string_literal: true

# This file setup LOAD_PATH to load Ruby Next own transpiled paths
# (we cannot use language/setup here, 'cause it requires Core to be loaded)

version = RubyNext.next_ruby_version
next_dirname = File.join(__dir__, "..", ".rbnext")
lib_path = File.realpath(File.join(__dir__, ".."))
current_index = $LOAD_PATH.find_index do |load_path|
  File.exist?(load_path) && File.realpath(load_path) == lib_path
end

loop do
  break unless version

  version_dir = File.join(next_dirname, version.segments[0..1].join("."))

  if File.exist?(version_dir)
    $LOAD_PATH.insert current_index, version_dir
    current_index += 1
  end

  version = RubyNext.next_ruby_version(version)
end
