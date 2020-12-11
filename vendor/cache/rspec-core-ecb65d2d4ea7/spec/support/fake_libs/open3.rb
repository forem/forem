unless caller.any? { |line| line.include?("rspec/core/bisect/shell_runner.rb") }
  raise "open3 loaded from unexpected file. " \
        "It is allowed to be loaded by the Bisect::ShellRunner " \
        "because that is not loaded in the same process as end-user code, " \
        "and we generally don't want open3 loaded for other things."
end

module Open3
end
