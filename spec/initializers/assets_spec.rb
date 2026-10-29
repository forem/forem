require "rails_helper"

RSpec.describe "Assets initializer" do # rubocop:disable RSpec/DescribeClass
  describe EsbuildSkippingTerserCompressor do
    let(:builds_dir) { Rails.root.join("app/assets/builds").to_s }
    let(:javascripts_dir) { Rails.root.join("app/assets/javascripts").to_s }

    it "registers EsbuildSkippingTerserCompressor as the :terser_skip_builds JS compressor" do
      compressor = Rails.application.assets.compressors.dig("application/javascript", :terser_skip_builds)
      expect(compressor).to eq(described_class)
    end

    it "configures production.rb to use :terser_skip_builds as the JS compressor" do
      production_config = Rails.root.join("config/environments/production.rb").read
      expect(production_config).to include("config.assets.js_compressor = :terser_skip_builds")
    end

    it "includes CACHE_KEY_VERSION and Terser::Compressor.cache_key in its cache_key" do
      expect(described_class.cache_key).to include(described_class::CACHE_KEY_VERSION)
      expect(described_class.cache_key).to include(Terser::Compressor.cache_key)
    end

    it "skips Terser compression for pre-minified esbuild bundles in app/assets/builds" do
      allow(Terser::Compressor).to receive(:call)

      input = {
        load_path: builds_dir,
        filename: "#{builds_dir}/mermaidRenderer.js",
        data: "(()=>{const x=1;console.log(x);})();\n"
      }

      expect(described_class.call(input)).to be_nil
      expect(Terser::Compressor).not_to have_received(:call)
    end

    it "skips Terser compression for pre-minified .min.js vendor assets" do
      allow(Terser::Compressor).to receive(:call)

      input = {
        load_path: Rails.root.join("vendor/assets/javascripts").to_s,
        filename: Rails.root.join("vendor/assets/javascripts/markdown-it.min.js").to_s,
        name: "markdown-it.min",
        data: "/*! markdown-it */function a(){}"
      }

      expect(described_class.call(input)).to be_nil
      expect(Terser::Compressor).not_to have_received(:call)
    end

    it "skips Terser compression for blazer and pghero engine bundles" do
      allow(Terser::Compressor).to receive(:call)

      %w[blazer/application pghero/application].each do |engine_bundle|
        input = {
          load_path: "/gems/#{engine_bundle.split('/').first}/app/assets/javascripts",
          filename: "/gems/#{engine_bundle}.js",
          name: engine_bundle,
          data: "function chart(){}"
        }

        expect(described_class.call(input)).to be_nil
      end

      expect(Terser::Compressor).not_to have_received(:call)
    end

    it "delegates non-build Sprockets JS assets to Terser::Compressor" do
      compressed_output = { data: "function foo(){return 1}", map: {} }
      allow(Terser::Compressor).to receive(:call).and_return(compressed_output)

      input = {
        load_path: javascripts_dir,
        filename: "#{javascripts_dir}/initializePage.js",
        data: "function foo() {\n  return 1;\n}\n"
      }

      expect(described_class.call(input)).to eq(compressed_output)
      expect(Terser::Compressor).to have_received(:call).with(input)
    end
  end

  describe "Build configuration hygiene" do
    it "does not declare a conflicting packageManager or engines.yarn in package.json alongside .yarnrc.yml yarnPath" do
      package_json = JSON.parse(Rails.root.join("package.json").read)
      yarnrc = Rails.root.join(".yarnrc.yml").read

      expect(yarnrc).to include("yarnPath: .yarn/releases/yarn-4.1.0.cjs")
      expect(package_json["packageManager"]).to be_nil
      expect(package_json.dig("engines", "yarn")).to be_nil
    end

    it "disables unnecessary postinstall build scripts for cypress, core-js, and core-js-pure" do
      package_json = JSON.parse(Rails.root.join("package.json").read)
      deps_meta = package_json.fetch("dependenciesMeta", {})

      expect(deps_meta.dig("cypress", "built")).to be(false)
      expect(deps_meta.dig("core-js", "built")).to be(false)
      expect(deps_meta.dig("core-js-pure", "built")).to be(false)
    end

    it "does not compile unused application.scss or leaf stylesheets in manifest.js" do
      expect(Rails.root.join("app/assets/stylesheets/application.scss").exist?).to be(false)

      manifest = Rails.root.join("app/assets/config/manifest.js").read
      expect(manifest).not_to include("link_directory ../stylesheets .css")
      %w[
        minimal.css
        views.css
        crayons.css
        admin.css
        ai_chat.css
        tags.css
        s3_direct_upload.css
        setup-mode.css
        feedback_messages.css
        themes/dark.css
        preact/onboarding-modal.css
        katex.css
      ].each do |stylesheet|
        expect(manifest).to include("//= link #{stylesheet}")
      end
    end

    it "does not include a committed bin/bundle binstub" do
      expect(Rails.root.join("bin/bundle").exist?).to be(false)
    end

    it "excludes test files from esbuild entryPoints" do
      esbuild_config = Rails.root.join("esbuild.config.mjs").read
      expect(esbuild_config).to include('ignore: ["**/*.test.*", "**/__tests__/**"]')
    end

    it "removes javascript:build from assets:precompile in production when app/assets/builds has compiled bundles" do
      Rails.application.load_tasks unless Rake::Task.task_defined?("assets:precompile")
      task = Rake::Task["assets:precompile"]
      original_prereqs = task.prerequisites.dup

      begin
        task.prerequisites << "javascript:build" unless task.prerequisites.include?("javascript:build")
        builds_dir = instance_double(Pathname)
        allow(builds_dir).to receive(:glob).with("*.{js,css}").and_return([Pathname.new("application.js")])
        allow(Rails.root).to receive(:join).and_call_original
        allow(Rails.root).to receive(:join).with("app/assets/builds").and_return(builds_dir)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("RAILS_ENV").and_return("production")

        load Rails.root.join("lib/tasks/post_precompile_assets.rake")

        expect(task.prerequisites).not_to include("javascript:build")
      ensure
        task.prerequisites.replace(original_prereqs)
      end
    end

    it "keeps javascript:build on assets:precompile in production when only .keep is present in app/assets/builds" do
      Rails.application.load_tasks unless Rake::Task.task_defined?("assets:precompile")
      task = Rake::Task["assets:precompile"]
      original_prereqs = task.prerequisites.dup

      begin
        task.prerequisites << "javascript:build" unless task.prerequisites.include?("javascript:build")
        builds_dir = instance_double(Pathname)
        allow(builds_dir).to receive(:glob).with("*.{js,css}").and_return([])
        allow(Rails.root).to receive(:join).and_call_original
        allow(Rails.root).to receive(:join).with("app/assets/builds").and_return(builds_dir)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("RAILS_ENV").and_return("production")

        load Rails.root.join("lib/tasks/post_precompile_assets.rake")

        expect(task.prerequisites).to include("javascript:build")
      ensure
        task.prerequisites.replace(original_prereqs)
      end
    end
  end
end
