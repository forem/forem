# Avoid this warning since it's unlikely to be fixed upstream.
# See: https://github.com/podigee/device_detector/issues/91
if (device_detector_source_path = Gem.loaded_specs["device_detector"]&.full_gem_path)
  parser_source_file_path = Pathname.new(device_detector_source_path) / "lib/device_detector/parser.rb"
  Warning.ignore(/regular expression/, parser_source_file_path.to_s)
end
