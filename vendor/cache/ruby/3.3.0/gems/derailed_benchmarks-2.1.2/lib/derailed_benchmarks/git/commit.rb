module DerailedBenchmarks
  # Represents a specific commit in a git repo
  #
  # Can be used to get information from the commit or to check it out
  #
  # commit = GitCommit.new(path: "path/to/repo", ref: "6e642963acec0ff64af51bd6fba8db3c4176ed6e")
  # commit.short_sha # => "6e64296"
  # commit.checkout! # Will check out the current commit at the repo in the path
  class Git::Commit
    attr_reader :ref, :description, :time, :short_sha, :log

    def initialize(path: , ref: , log_dir: Pathname.new("/dev/null"))
      @in_git_path = Git::InPath.new(path)
      @ref = ref
      @log = log_dir.join("#{file_safe_ref}.bench.txt")

      Dir.chdir(path) do
        checkout!
        @description = @in_git_path.description
        @short_sha = @in_git_path.short_sha
        @time = @in_git_path.time
      end
    end

    alias :desc :description
    alias :file :log

    def checkout!
      @in_git_path.checkout!(ref)
    end

    private def file_safe_ref
      ref.gsub('/', ':')
    end
  end
end
