# frozen_string_literal: true

module KnapsackPro
  module RepositoryAdapters
    class GitAdapter < BaseAdapter
      def commit_hash
        `git -C "#{working_dir}" rev-parse HEAD`.strip
      end

      def branch
        `git -C "#{working_dir}" rev-parse --abbrev-ref HEAD`.strip
      end

      def branches
        str_branches = `git rev-parse --abbrev-ref --branches`
        str_branches.split("\n")
      end

      def commit_authors
        authors = git_commit_authors
          .split("\n")
          .map { |line| line.strip }
          .map { |line| line.split("\t") }
          .map do |commits, author|
            { commits: commits.to_i, author: KnapsackPro::MaskString.call(author) }
          end

        raise if authors.empty?

        authors
      rescue Exception
        []
      end

      def build_author
        author = KnapsackPro::MaskString.call(git_build_author.strip)
        raise if author.empty?
        author
      rescue Exception
        "no git <no.git@example.com>"
      end

      private

      def git_commit_authors
        if KnapsackPro::Config::Env.ci? && shallow_repository?
          command = 'git fetch --shallow-since "one month ago" --quiet 2>/dev/null'
          begin
            Timeout.timeout(5) do
              `#{command}`
            end
          rescue Timeout::Error
            KnapsackPro.logger.debug("Skip the `#{command}` command because it took too long.")
          end
        end

        `git log --since "one month ago" 2>/dev/null | git shortlog --summary --email 2>/dev/null`
      end

      def git_build_author
        `git log --format="%aN <%aE>" -1 2>/dev/null`
      end

      def shallow_repository?
        result = `git rev-parse --is-shallow-repository 2>/dev/null`
        result.strip == 'true'
      end

      def working_dir
        dir = KnapsackPro::Config::Env.project_dir
        File.expand_path(dir)
      end
    end
  end
end
