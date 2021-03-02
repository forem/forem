# encoding: utf-8

RSpec.describe "::RSpec::Core::ExampleGroup" do
  context "does not cause problems when users reference a top level constant of the same name" do
    file_in_outer_group = File
    example { expect(File).to eq ::File }
    example { expect(file_in_outer_group).to be(::File) }

    describe "File" do
      file_in_inner_group = File
      example { expect(File).to eq ::File }
      example { expect(file_in_inner_group).to be(::File) }
    end
  end
end
