require 'inline_svg'

class WorkingCustomTransform < InlineSvg::CustomTransformation
  def transform(doc)
    doc = Nokogiri::XML::Document.parse(doc.to_html)
    svg = doc.at_css 'svg'
    svg['custom'] = value
    doc
  end
end

describe InlineSvg::ActionView::Helpers do

  let(:helper) { ( Class.new { include InlineSvg::ActionView::Helpers } ).new }

  shared_examples "inline_svg helper" do |helper_method:|

    context "when passed the name of an SVG that does not exist" do
      after(:each) do
        InlineSvg.reset_configuration!
      end

      context "and configured to raise" do
        it "raises an exception" do
          InlineSvg.configure do |config|
            config.raise_on_file_not_found = true
          end

          allow(InlineSvg::AssetFile).to receive(:named).
            with('some-missing-file.svg').
            and_raise(InlineSvg::AssetFile::FileNotFound.new)

          expect {
            helper.send(helper_method, 'some-missing-file.svg')
          }.to raise_error(InlineSvg::AssetFile::FileNotFound)
        end
      end

      it "returns an empty, html safe, SVG document as a placeholder" do
        allow(InlineSvg::AssetFile).to receive(:named).
          with('some-missing-file.svg').
          and_raise(InlineSvg::AssetFile::FileNotFound.new)

        output = helper.send(helper_method, 'some-missing-file.svg')
        expect(output).to eq "<svg><!-- SVG file not found: 'some-missing-file.svg' --></svg>"
        expect(output).to be_html_safe
      end

      it "escapes malicious input" do
        malicious = "--></svg><script>alert(1)</script><svg>.svg"
        allow(InlineSvg::AssetFile).to receive(:named).
          with(malicious).
          and_raise(InlineSvg::AssetFile::FileNotFound.new)

        output = helper.send(helper_method, malicious)
        expect(output).to eq "<svg><!-- SVG file not found: '--&gt;&lt;/svg&gt;&lt;script&gt;alert(1)&lt;/script&gt;&lt;svg&gt;.svg' --></svg>"
        expect(output).to be_html_safe
      end

      it "gives a helpful hint when no .svg extension is provided in the filename" do
        allow(InlineSvg::AssetFile).to receive(:named).
          with('missing-file-with-no-extension').
          and_raise(InlineSvg::AssetFile::FileNotFound.new)

        output = helper.send(helper_method, 'missing-file-with-no-extension')
        expect(output).to eq "<svg><!-- SVG file not found: 'missing-file-with-no-extension' (Try adding .svg to your filename) --></svg>"
      end

      it "allows the CSS class on the empty SVG document to be changed" do
        InlineSvg.configure do |config|
          config.svg_not_found_css_class = 'missing-svg'
        end

        allow(InlineSvg::AssetFile).to receive(:named).
          with('some-other-missing-file.svg').
          and_raise(InlineSvg::AssetFile::FileNotFound.new)

        output = helper.send(helper_method, 'some-other-missing-file.svg')
        expect(output).to eq "<svg class='missing-svg'><!-- SVG file not found: 'some-other-missing-file.svg' --></svg>"
        expect(output).to be_html_safe
      end

      context "and a fallback that does exist" do
        it "displays the fallback" do
          allow(InlineSvg::AssetFile).to receive(:named).
            with('missing.svg').
            and_raise(InlineSvg::AssetFile::FileNotFound.new)

          fallback_file = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" xml:lang="en"><!-- This is a comment --></svg>
SVG
          allow(InlineSvg::AssetFile).to receive(:named).with('fallback.svg').and_return(fallback_file)
          expect(helper.send(helper_method, 'missing.svg', fallback: 'fallback.svg')).to eq fallback_file
        end
      end
    end

    context "when passed an existing SVG file" do

      context "and no options" do
        it "returns a html safe version of the file's contents" do
          example_file = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" xml:lang="en"><!-- This is a comment --></svg>
SVG
          allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(example_file)
          expect(helper.send(helper_method, 'some-file')).to eq example_file
        end
      end

      context "and the 'title' option" do
        it "adds the title node to the SVG output" do
          input_svg = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" role="presentation" xml:lang="en"></svg>
SVG
          expected_output = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" role="presentation" xml:lang="en"><title>A title</title></svg>
SVG
          allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(input_svg)
          expect(helper.send(helper_method, 'some-file', title: 'A title')).to eq expected_output
        end
      end

      context "and the 'desc' option" do
        it "adds the description node to the SVG output" do
          input_svg = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" role="presentation" xml:lang="en"></svg>
SVG
          expected_output = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" role="presentation" xml:lang="en"><desc>A description</desc></svg>
SVG
          allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(input_svg)
          expect(helper.send(helper_method, 'some-file', desc: 'A description')).to eq expected_output
        end
      end

      context "and the 'nocomment' option" do
        it "strips comments and other unknown/unsafe nodes from the output" do
          input_svg = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" xml:lang="en"><!-- This is a comment --></svg>
SVG
          expected_output = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" xml:lang="en"></svg>
SVG
          allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(input_svg)
          expect(helper.send(helper_method, 'some-file', nocomment: true)).to eq expected_output
        end
      end

      context "and the 'aria_hidden' option" do
        it "sets 'aria-hidden=true' in the output" do
          input_svg = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" xml:lang="en"></svg>
SVG
          expected_output = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" xml:lang="en" aria-hidden="true"></svg>
SVG
          allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(input_svg)
          expect(helper.send(helper_method, 'some-file', aria_hidden: true)).to eq expected_output
        end
      end

      context "and all options" do
        it "applies all expected transformations to the output" do
          input_svg = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" xml:lang="en"><!-- This is a comment --></svg>
SVG
          expected_output = <<-SVG
<svg xmlns="http://www.w3.org/2000/svg" xml:lang="en"><title>A title</title><desc>A description</desc></svg>
SVG
          allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(input_svg)
          expect(helper.send(helper_method, 'some-file', title: 'A title', desc: 'A description', nocomment: true)).to eq expected_output
        end
      end

      context "with custom transformations" do
        before(:each) do
          InlineSvg.configure do |config|
            config.add_custom_transformation({attribute: :custom, transform: WorkingCustomTransform})
          end
        end

        after(:each) do
          InlineSvg.reset_configuration!
        end

        it "applies custm transformations to the output" do
          input_svg = <<-SVG
<svg></svg>
SVG
          expected_output = <<-SVG
<svg custom="some value"></svg>
SVG
          allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(input_svg)
          expect(helper.send(helper_method, 'some-file', custom: 'some value')).to eq expected_output
        end
      end

      context "with custom transformations using a default value" do
        before(:each) do
          InlineSvg.configure do |config|
            config.add_custom_transformation({attribute: :custom, transform: WorkingCustomTransform, default_value: 'default value'})
          end
        end

        after(:each) do
          InlineSvg.reset_configuration!
        end

        context "without passing the attribute value" do
          it "applies custom transformations to the output using the default value" do
            input_svg = '<svg></svg>'

            allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(input_svg)

            expect(helper.send(helper_method, 'some-file')).to eq "<svg custom=\"default value\"></svg>\n"
          end
        end

        context "passing the attribute value" do
          it "applies custom transformations to the output" do
            input_svg = '<svg></svg>'

            allow(InlineSvg::AssetFile).to receive(:named).with('some-file').and_return(input_svg)

            expect(helper.send(helper_method, 'some-file', custom: 'some value')).to eq "<svg custom=\"some value\"></svg>\n"
          end
        end
      end

    end
    context 'argument polimorphizm' do
      let(:argument) { double('argument') }
      it 'accept IO' do
        expect(InlineSvg::IOResource).to receive(:===).with(argument).and_return(true)
        expect(InlineSvg::IOResource).to receive(:read).with(argument)
        expect(InlineSvg::AssetFile).to_not receive(:named)
        helper.send(helper_method, argument)
      end
      it 'accept filename' do
        expect(InlineSvg::IOResource).to receive(:===).with(argument).and_return(false)
        expect(InlineSvg::IOResource).to_not receive(:read)
        expect(InlineSvg::AssetFile).to receive(:named).with(argument)
        helper.send(helper_method, argument)
      end
    end
    context 'when passed IO object argument' do
      let(:io_object) { double('io_object') }
      let(:file_path) { File.expand_path('../../files/example.svg', __FILE__) }
      let(:answer) { File.read(file_path) }
      it 'return valid svg' do
        expect(InlineSvg::IOResource).to receive(:===).with(io_object).and_return(true)
        expect(InlineSvg::IOResource).to receive(:read).with(io_object).and_return("<svg><!-- Test IO --></svg>")
        output = helper.send(helper_method, io_object)
        expect(output).to eq "<svg><!-- Test IO --></svg>\n"
        expect(output).to be_html_safe
      end

      it 'return valid svg for file' do
        output = helper.send(helper_method, File.new(file_path))
        expect(output).to eq "<svg xmlns=\"http://www.w3.org/2000/svg\" xml:lang=\"en\" role=\"presentation\"><!-- This is a test comment --></svg>\n"
        expect(output).to be_html_safe
      end

    end
  end

  describe '#inline_svg' do
    it_behaves_like "inline_svg helper", helper_method: :inline_svg
  end

  describe '#inline_svg_tag' do
    it_behaves_like "inline_svg helper", helper_method: :inline_svg_tag
  end

  describe '#inline_svg_tag' do
    it_behaves_like "inline_svg helper", helper_method: :inline_svg_pack_tag
  end
end
