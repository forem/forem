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

    it "includes Terser::Compressor.cache_key in its cache_key" do
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
end
