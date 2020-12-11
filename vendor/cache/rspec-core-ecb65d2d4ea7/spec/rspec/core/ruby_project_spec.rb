module RSpec
  module Core
    RSpec.describe RubyProject do

      describe "#determine_root" do

        context "with ancestor containing spec directory" do
          it "returns ancestor containing the spec directory" do
            allow(RubyProject).to receive(:ascend_until).and_return('foodir')
            expect(RubyProject.determine_root).to eq("foodir")
          end
        end

        context "without ancestor containing spec directory" do
          it "returns current working directory" do
            allow(RubyProject).to receive(:find_first_parent_containing).and_return(nil)
            expect(RubyProject.determine_root).to eq(".")
          end
        end

      end

      describe "#ascend_until" do
        subject { RubyProject }

        def expect_ascend(source_path, *yielded_paths)
          expect { |probe|
            allow(File).to receive(:expand_path).with('.') { source_path }
            subject.ascend_until(&probe)
          }.to yield_successive_args(*yielded_paths)
        end

        it "works with a normal path" do
          expect_ascend("/var/ponies", "/var/ponies", "/var", "/")
        end

        it "works with a path with a trailing slash" do
          expect_ascend("/var/ponies/", "/var/ponies", "/var", "/")
        end

        it "works with a path with double slashes" do
          expect_ascend("/var//ponies/", "/var/ponies", "/var", "/")
        end

        it "works with a path with escaped slashes" do
          expect_ascend("/var\\/ponies/", "/var\\/ponies", "/")
        end
      end
    end
  end
end
