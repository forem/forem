module DerailedBenchmarks
  # A class for running commands in a git directory
  #
  # It's faster to check if we're already in that directory instead
  # of having to `cd` into each time. https://twitter.com/schneems/status/1305196730170961920
  #
  # Example:
  #
  #   in_git_path = InGitPath.new(`bundle info heapy --path`.strip)
  #   in_git_path.checkout!("f0f92b06156f2274021aa42f15326da041ee9009")
  #   in_git_path.short_sha # => "f0f92b0"
  class Git::InPath
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def description
      run!("git log --oneline --format=%B -n 1 HEAD | head -n 1")
    end

    def short_sha
      run!("git rev-parse --short HEAD")
    end

    def time_stamp_string
      run!("git log -n 1 --pretty=format:%ci") # https://stackoverflow.com/a/25921837/147390
    end

    def branch
      branch = run!("git rev-parse --abbrev-ref HEAD")
      branch == "HEAD" ? nil : branch
    end

    def checkout!(ref)
      run!("git checkout '#{ref}' 2>&1")
    end

    def time
      DateTime.parse(time_stamp_string)
    end

    def run(cmd)
      if Dir.pwd == path
        out = `#{cmd}`.strip
      else
        out = `cd #{path} && #{cmd}`.strip
      end
      out
    end

    def run!(cmd)
      out = run(cmd)
      raise "Error while running #{cmd.inspect}: #{out}" unless $?.success?
      out
    end
  end
end
