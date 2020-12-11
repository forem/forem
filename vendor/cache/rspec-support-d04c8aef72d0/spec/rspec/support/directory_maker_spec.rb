require "spec_helper"
require "fileutils"

RSpec::Support.require_rspec_support("directory_maker")

module RSpec::Support
  RSpec.describe DirectoryMaker do
    shared_examples_for "an mkdir_p implementation" do
      include_context "isolated directory"

      let(:dirname) { File.join(%w[tmp a recursive structure]) }

      def directory_exists?(dirname)
        File.exist?(dirname) && File.directory?(dirname)
      end

      it "makes directories recursively" do
        mkdir_p.call(dirname)
        expect(directory_exists?(dirname)).to be true
      end

      it "does not raise if the directory already exists" do
        Dir.mkdir("tmp")
        mkdir_p.call(dirname)
        expect(directory_exists?(dirname)).to be true
      end

      context "when a file already exists" do
        before { File.open("tmp", "w") }

        it "raises, as it can't make the directory", :failing_on_windows_ci do
          expect {
            mkdir_p.call(dirname)
          }.to raise_error(Errno::EEXIST)
        end
      end

      context "when the path specified is absolute" do
        let(:dirname) { "bees/ponies" }

        it "makes directories recursively" do
          mkdir_p.call(File.expand_path(dirname))
          expect(directory_exists?(dirname)).to be true
        end
      end
    end

    describe ".mkdir_p" do
      subject(:mkdir_p) { DirectoryMaker.method(:mkdir_p) }
      it_behaves_like "an mkdir_p implementation"
    end

    describe "FileUtils.mkdir_p" do
      subject(:mkdir_p) { FileUtils.method(:mkdir_p) }
      it_behaves_like "an mkdir_p implementation"
    end
  end
end
