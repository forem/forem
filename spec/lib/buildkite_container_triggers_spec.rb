require "rails_helper"
require "open3"
require "tmpdir"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "Buildkite container build triggers" do
  let(:build_containers_script) { Rails.root.join("scripts/build_containers.sh").to_s }
  let(:create_pr_build_script) { Rails.root.join("scripts/create_buildkite_pr_build.sh").to_s }

  def write_executable(path, content)
    File.write(path, content)
    File.chmod(0o755, path)
  end

  describe "scripts/build_containers.sh" do
    it "skips PR container builds when only non-container application files changed" do
      Dir.mktmpdir do |tmpdir|
        docker_log = File.join(tmpdir, "docker.log")

        write_executable(File.join(tmpdir, "git"), <<~SH)
          #!/bin/bash
          if [[ "$1" == "rev-parse" && "$2" == "--verify" ]]; then
            exit 0
          elif [[ "$1" == "diff" && "$2" == "--name-only" ]]; then
            printf "app/models/article.rb\\nspec/models/article_spec.rb\\nconfig/locales/en.yml\\n"
            exit 0
          fi
          exit 0
        SH

        write_executable(File.join(tmpdir, "docker"), <<~SH)
          #!/bin/bash
          echo "$@" >> "#{docker_log}"
        SH

        env = {
          "PATH" => "#{tmpdir}:#{ENV.fetch('PATH', '')}",
          "BUILDKITE_BRANCH" => "feature/update-article",
          "BUILDKITE_PULL_REQUEST" => "24390",
          "BUILDKITE_PULL_REQUEST_BASE_BRANCH" => "main",
          "BUILDKITE_COMMIT" => "abc1234567890"
        }

        output, status = Open3.capture2e(env, build_containers_script)

        expect(status.exitstatus).to eq(0)
        expect(output).to include(
          "No container-relevant files changed relative to main. Skipping PR container build.",
        )
        expect(File.exist?(docker_log)).to be(false)
      end
    end

    it "runs PR container builds when container or dependency files changed" do
      %w[
        Containerfile
        Containerfile.base
        Dockerfile
        .dockerignore
        .buildkite/pipeline.containers.yml
        .github/workflows/buildkite.yml
        scripts/build_containers.sh
        scripts/create_buildkite_pr_build.sh
        scripts/entrypoint.sh
        scripts/bundle.sh
        .ruby-version
        Gemfile
        Gemfile.lock
        vendor/cache/rack-2.2.8.gem
        .nvmrc
        package.json
        yarn.lock
        esbuild.config.mjs
      ].each do |changed_file|
        Dir.mktmpdir do |tmpdir|
          docker_log = File.join(tmpdir, "docker.log")

          write_executable(File.join(tmpdir, "git"), <<~SH)
            #!/bin/bash
            if [[ "$1" == "rev-parse" && "$2" == "--verify" ]]; then
              exit 0
            elif [[ "$1" == "diff" && "$2" == "--name-only" ]]; then
              printf "app/models/article.rb\\n#{changed_file}\\n"
              exit 0
            fi
            exit 0
          SH

          write_executable(File.join(tmpdir, "docker"), <<~SH)
            #!/bin/bash
            echo "$@" >> "#{docker_log}"
          SH

          env = {
            "PATH" => "#{tmpdir}:#{ENV.fetch('PATH', '')}",
            "BUILDKITE_BRANCH" => "feature/container-change",
            "BUILDKITE_PULL_REQUEST" => "24391",
            "BUILDKITE_PULL_REQUEST_BASE_BRANCH" => "main",
            "BUILDKITE_COMMIT" => "abc1234567890"
          }

          output, status = Open3.capture2e(env, build_containers_script)

          expect(status.exitstatus).to eq(0), "Expected 0 exit status for #{changed_file}, got: #{output}"
          expect(output).to include("Container-relevant files changed relative to main:")
          expect(output).to include(changed_file)
          expect(output).to include("Building containers for pull request #24391...")
          expect(File.read(docker_log)).to include("build --target builder")
        end
      end
    end

    it "runs PR container builds when FORCE_CONTAINER_BUILD=true even if no relevant files changed" do
      Dir.mktmpdir do |tmpdir|
        docker_log = File.join(tmpdir, "docker.log")

        write_executable(File.join(tmpdir, "git"), <<~SH)
          #!/bin/bash
          printf "app/models/article.rb\\n"
        SH

        write_executable(File.join(tmpdir, "docker"), <<~SH)
          #!/bin/bash
          echo "$@" >> "#{docker_log}"
        SH

        env = {
          "PATH" => "#{tmpdir}:#{ENV.fetch('PATH', '')}",
          "BUILDKITE_BRANCH" => "feature/forced",
          "BUILDKITE_PULL_REQUEST" => "24392",
          "BUILDKITE_COMMIT" => "abc1234567890",
          "FORCE_CONTAINER_BUILD" => "true"
        }

        output, status = Open3.capture2e(env, build_containers_script)

        expect(status.exitstatus).to eq(0)
        expect(output).to include("FORCE_CONTAINER_BUILD is set; proceeding with container build.")
        expect(File.read(docker_log)).to include("build --target builder")
      end
    end

    it "always builds production containers on main branch pushes" do
      Dir.mktmpdir do |tmpdir|
        docker_log = File.join(tmpdir, "docker.log")

        write_executable(File.join(tmpdir, "docker"), <<~SH)
          #!/bin/bash
          echo "$@" >> "#{docker_log}"
        SH

        env = {
          "PATH" => "#{tmpdir}:#{ENV.fetch('PATH', '')}",
          "BUILDKITE_BRANCH" => "main",
          "BUILDKITE_PULL_REQUEST" => "false",
          "BUILDKITE_COMMIT" => "abc1234567890"
        }

        output, status = Open3.capture2e(env, build_containers_script)

        expect(status.exitstatus).to eq(0)
        expect(output).to include("Building Production Containers...")
        expect(File.read(docker_log)).to include("push quay.io/forem/forem:production")
      end
    end
  end

  describe "scripts/create_buildkite_pr_build.sh" do
    it "skips triggering Buildkite when the PR only touches non-container files" do
      Dir.mktmpdir do |tmpdir|
        curl_log = File.join(tmpdir, "curl.log")
        event_path = File.join(tmpdir, "event.json")

        File.write(event_path, {
          issue: { number: 24_395 },
          comment: {
            body: "/ci",
            html_url: "https://github.com/forem/forem/pull/24395#issuecomment-1",
            user: { login: "maintainer" }
          }
        }.to_json)

        write_executable(File.join(tmpdir, "curl"), <<~SH)
          #!/bin/bash
          echo "$@" >> "#{curl_log}"
          if [[ "$*" == *"/pulls/24395/files"* ]]; then
            echo '[{"filename":"app/models/article.rb"},{"filename":"spec/models/article_spec.rb"}]'
          fi
        SH

        env = {
          "PATH" => "#{tmpdir}:#{ENV.fetch('PATH', '')}",
          "BUILDKITE_API_ACCESS_TOKEN" => "test-buildkite-token",
          "PIPELINE" => "forem/build-containers",
          "GITHUB_TOKEN" => "test-gh-token",
          "GITHUB_REPOSITORY" => "forem/forem",
          "GITHUB_EVENT_PATH" => event_path,
          "PULL_REQUEST_ID" => "24395"
        }

        output, status = Open3.capture2e(env, create_pr_build_script)

        expect(status.exitstatus).to eq(0)
        expect(output).to include(
          "No container-relevant files changed in PR #24395; skipping Buildkite container build.",
        )
        expect(File.read(curl_log)).not_to include("api.buildkite.com")
      end
    end

    it "triggers Buildkite when the PR modifies a container-relevant file" do
      Dir.mktmpdir do |tmpdir|
        curl_log = File.join(tmpdir, "curl.log")
        event_path = File.join(tmpdir, "event.json")

        File.write(event_path, {
          issue: { number: 24_396 },
          comment: {
            body: "/ci",
            html_url: "https://github.com/forem/forem/pull/24396#issuecomment-1",
            user: { login: "maintainer" }
          }
        }.to_json)

        write_executable(File.join(tmpdir, "curl"), <<~SH)
          #!/bin/bash
          echo "$@" >> "#{curl_log}"
          if [[ "$*" == *"/pulls/24396/files"* ]]; then
            echo '[{"filename":"Containerfile"},{"filename":"app/models/article.rb"}]'
          elif [[ "$*" == *"/pulls/24396"* ]]; then
            echo '{"base":{"repo":{"full_name":"forem/forem"},"ref":"main"},"head":{"repo":{"full_name":"fork/forem"},"ref":"patch-1","sha":"deadbeef"},"user":{"login":"contributor"}}'
          elif [[ "$*" == *"/users/contributor"* ]]; then
            echo '{"name":"Contributor","email":null}'
          elif [[ "$*" == *"api.buildkite.com"* ]]; then
            echo '{"web_url":"https://buildkite.com/forem/build-containers/builds/1"}'
          fi
        SH

        env = {
          "PATH" => "#{tmpdir}:#{ENV.fetch('PATH', '')}",
          "BUILDKITE_API_ACCESS_TOKEN" => "test-buildkite-token",
          "PIPELINE" => "forem/build-containers",
          "GITHUB_TOKEN" => "test-gh-token",
          "GITHUB_REPOSITORY" => "forem/forem",
          "GITHUB_EVENT_PATH" => event_path,
          "PULL_REQUEST_ID" => "24396"
        }

        output, status = Open3.capture2e(env, create_pr_build_script)

        expect(status.exitstatus).to eq(0)
        expect(output).to include("Container-relevant files changed in PR #24396:")
        expect(output).to include("Containerfile")
        expect(output).to include("https://buildkite.com/forem/build-containers/builds/1")
        expect(File.read(curl_log)).to include("api.buildkite.com")
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
