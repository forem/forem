# encoding: utf-8
require_relative 'common'

describe 'Sanitize::CSS' do
  make_my_diffs_pretty!
  parallelize_me!

  describe 'instance methods' do
    before do
      @default = Sanitize::CSS.new
      @relaxed = Sanitize::CSS.new(Sanitize::Config::RELAXED[:css])
      @custom  = Sanitize::CSS.new(:properties => %w[background color width])
    end

    describe '#properties' do
      it 'should sanitize CSS properties' do
        css = 'background: #fff; width: expression(alert("hi"));'

        _(@default.properties(css)).must_equal ' '
        _(@relaxed.properties(css)).must_equal 'background: #fff; '
        _(@custom.properties(css)).must_equal 'background: #fff; '
      end

      it 'should allow allowlisted URL protocols' do
        [
          "background: url(relative.jpg)",
          "background: url('relative.jpg')",
          "background: url(http://example.com/http.jpg)",
          "background: url('ht\\tp://example.com/http.jpg')",
          "background: url(https://example.com/https.jpg)",
          "background: url('https://example.com/https.jpg')",
        ].each do |css|
          _(@default.properties(css)).must_equal ''
          _(@relaxed.properties(css)).must_equal css
          _(@custom.properties(css)).must_equal ''
        end
      end

      it 'should not allow non-allowlisted URL protocols' do
        [
          "background: url(javascript:alert(0))",
          "background: url(ja\\56 ascript:alert(0))",
          "background: url('javascript:foo')",
          "background: url('ja\\56 ascript:alert(0)')",
          "background: url('ja\\va\\script\\:alert(0)')",
          "background: url('javas\\\ncript:alert(0)')",
          "background: url('java\\0script:foo')"
        ].each do |css|
          _(@default.properties(css)).must_equal ''
          _(@relaxed.properties(css)).must_equal ''
          _(@custom.properties(css)).must_equal ''
        end
      end

      it 'should not allow -moz-binding' do
        css = "-moz-binding:url('http://ha.ckers.org/xssmoz.xml#xss')"

        _(@default.properties(css)).must_equal ''
        _(@relaxed.properties(css)).must_equal ''
        _(@custom.properties(css)).must_equal ''
      end

      it 'should not allow expressions' do
        [
          "width:expression(alert(1))",
          "width:  /**/expression(alert(1)",
          "width:e\\78 pression(\n\nalert(\n1)",
          "width:\nexpression(alert(1));",
          "xss:expression(alert(1))",
          "height: foo(expression(alert(1)));"
        ].each do |css|
          _(@default.properties(css)).must_equal ''
          _(@relaxed.properties(css)).must_equal ''
          _(@custom.properties(css)).must_equal ''
        end
      end

      it 'should not allow behaviors' do
        css = "behavior: url(xss.htc);"

        _(@default.properties(css)).must_equal ''
        _(@relaxed.properties(css)).must_equal ''
        _(@custom.properties(css)).must_equal ''
      end

      describe 'when :allow_comments is true' do
        it 'should preserve comments' do
          _(@relaxed.properties('color: #fff; /* comment */ width: 100px;'))
            .must_equal 'color: #fff; /* comment */ width: 100px;'

          _(@relaxed.properties("color: #fff; /* \n\ncomment */ width: 100px;"))
            .must_equal "color: #fff; /* \n\ncomment */ width: 100px;"
        end
      end

      describe 'when :allow_comments is false' do
        it 'should strip comments' do
          _(@custom.properties('color: #fff; /* comment */ width: 100px;'))
            .must_equal 'color: #fff;  width: 100px;'

          _(@custom.properties("color: #fff; /* \n\ncomment */ width: 100px;"))
            .must_equal 'color: #fff;  width: 100px;'
        end
      end

      describe 'when :allow_hacks is true' do
        it 'should allow common CSS hacks' do
          _(@relaxed.properties('_border: 1px solid #fff; *width: 10px'))
            .must_equal '_border: 1px solid #fff; *width: 10px'
        end
      end

      describe 'when :allow_hacks is false' do
        it 'should not allow common CSS hacks' do
          _(@custom.properties('_border: 1px solid #fff; *width: 10px'))
            .must_equal ' '
        end
      end
    end

    describe '#stylesheet' do
      it 'should sanitize a CSS stylesheet' do
        css = %[
          /* Yay CSS! */
          .foo { color: #fff; }
          #bar { background: url(yay.jpg); }

          @media screen (max-width:480px) {
            .foo { width: 400px; }
            #bar:not(.baz) { height: 100px; }
          }
        ].strip

        _(@default.stylesheet(css).strip).must_equal %[
          .foo {  }
          #bar {  }
        ].strip

        _(@relaxed.stylesheet(css)).must_equal css

        _(@custom.stylesheet(css).strip).must_equal %[
          .foo { color: #fff; }
          #bar {  }
        ].strip
      end

      describe 'when :allow_comments is true' do
        it 'should preserve comments' do
          _(@relaxed.stylesheet('.foo { color: #fff; /* comment */ width: 100px; }'))
            .must_equal '.foo { color: #fff; /* comment */ width: 100px; }'

          _(@relaxed.stylesheet(".foo { color: #fff; /* \n\ncomment */ width: 100px; }"))
            .must_equal ".foo { color: #fff; /* \n\ncomment */ width: 100px; }"
        end
      end

      describe 'when :allow_comments is false' do
        it 'should strip comments' do
          _(@custom.stylesheet('.foo { color: #fff; /* comment */ width: 100px; }'))
            .must_equal '.foo { color: #fff;  width: 100px; }'

          _(@custom.stylesheet(".foo { color: #fff; /* \n\ncomment */ width: 100px; }"))
            .must_equal '.foo { color: #fff;  width: 100px; }'
        end
      end

      describe 'when :allow_hacks is true' do
        it 'should allow common CSS hacks' do
          _(@relaxed.stylesheet('.foo { _border: 1px solid #fff; *width: 10px }'))
            .must_equal '.foo { _border: 1px solid #fff; *width: 10px }'
        end
      end

      describe 'when :allow_hacks is false' do
        it 'should not allow common CSS hacks' do
          _(@custom.stylesheet('.foo { _border: 1px solid #fff; *width: 10px }'))
            .must_equal '.foo {  }'
        end
      end
    end

    describe '#tree!' do
      it 'should sanitize a Crass CSS parse tree' do
        tree = Crass.parse(String.new("@import url(foo.css);\n") <<
          ".foo { background: #fff; font: 16pt 'Comic Sans MS'; }\n" <<
          "#bar { top: 125px; background: green; }")

        _(@custom.tree!(tree)).must_be_same_as tree

        _(Crass::Parser.stringify(tree)).must_equal String.new("\n") <<
            ".foo { background: #fff;  }\n" <<
            "#bar {  background: green; }"
      end
    end
  end

  describe 'class methods' do
    describe '.properties' do
      it 'should sanitize CSS properties with the given config' do
        css = 'background: #fff; width: expression(alert("hi"));'

        _(Sanitize::CSS.properties(css)).must_equal ' '
        _(Sanitize::CSS.properties(css, Sanitize::Config::RELAXED[:css])).must_equal 'background: #fff; '
        _(Sanitize::CSS.properties(css, :properties => %w[background color width])).must_equal 'background: #fff; '
      end
    end

    describe '.stylesheet' do
      it 'should sanitize a CSS stylesheet with the given config' do
        css = %[
          /* Yay CSS! */
          .foo { color: #fff; }
          #bar { background: url(yay.jpg); }

          @media screen (max-width:480px) {
            .foo { width: 400px; }
            #bar:not(.baz) { height: 100px; }
          }
        ].strip

        _(Sanitize::CSS.stylesheet(css).strip).must_equal %[
          .foo {  }
          #bar {  }
        ].strip

        _(Sanitize::CSS.stylesheet(css, Sanitize::Config::RELAXED[:css])).must_equal css

        _(Sanitize::CSS.stylesheet(css, :properties => %w[background color width]).strip).must_equal %[
          .foo { color: #fff; }
          #bar {  }
        ].strip
      end
    end

    describe '.tree!' do
      it 'should sanitize a Crass CSS parse tree with the given config' do
        tree = Crass.parse(String.new("@import url(foo.css);\n") <<
          ".foo { background: #fff; font: 16pt 'Comic Sans MS'; }\n" <<
          "#bar { top: 125px; background: green; }")

        _(Sanitize::CSS.tree!(tree, :properties => %w[background color width])).must_be_same_as tree

        _(Crass::Parser.stringify(tree)).must_equal String.new("\n") <<
            ".foo { background: #fff;  }\n" <<
            "#bar {  background: green; }"
      end
    end
  end

  describe 'functionality' do
    before do
      @default = Sanitize::CSS.new
      @relaxed = Sanitize::CSS.new(Sanitize::Config::RELAXED[:css])
    end

    # https://github.com/rgrove/sanitize/issues/121
    it 'should parse the contents of @media rules properly' do
      css = '@media { p[class="center"] { text-align: center; }}'
      _(@relaxed.stylesheet(css)).must_equal css

      css = %[
        @media (max-width: 720px) {
          p.foo > .bar { float: right; width: expression(body.scrollLeft + 50 + 'px'); }
          #baz { color: green; }

          @media (orientation: portrait) {
            #baz { color: red; }
          }
        }
      ].strip

      _(@relaxed.stylesheet(css)).must_equal %[
        @media (max-width: 720px) {
          p.foo > .bar { float: right;  }
          #baz { color: green; }

          @media (orientation: portrait) {
            #baz { color: red; }
          }
        }
      ].strip
    end

    it 'should parse @page rules properly' do
      css = %[
        @page { margin: 2cm } /* All margins set to 2cm */

        @page :right {
          @top-center { content: "Preliminary edition" }
          @bottom-center { content: counter(page) }
        }

        @page {
          size: 8.5in 11in;
          margin: 10%;

          @top-left {
            content: "Hamlet";
          }
          @top-right {
            content: "Page " counter(page);
          }
        }
      ].strip

      _(@relaxed.stylesheet(css)).must_equal css
    end

    describe ":at_rules" do
      it "should remove blockless at-rules that aren't allowlisted" do
        css = %[
          @charset 'utf-8';
          @import url('foo.css');
          .foo { color: green; }
        ].strip

        _(@relaxed.stylesheet(css).strip).must_equal %[
          .foo { color: green; }
        ].strip
      end

      describe "when blockless at-rules are allowlisted" do
        before do
          @scss = Sanitize::CSS.new(Sanitize::Config.merge(Sanitize::Config::RELAXED[:css], {
            :at_rules => ['charset', 'import']
          }))
        end

        it "should not remove them" do
          css = %[
            @charset 'utf-8';
            @import url('foo.css');
            .foo { color: green; }
          ].strip

          _(@scss.stylesheet(css)).must_equal %[
            @charset 'utf-8';
            @import url('foo.css');
            .foo { color: green; }
          ].strip
        end

        it "should remove them if they have invalid blocks" do
          css = %[
            @charset { color: green }
            @import { color: green }
            .foo { color: green; }
          ].strip

          _(@scss.stylesheet(css).strip).must_equal %[
            .foo { color: green; }
          ].strip
        end
      end

      describe "when validating @import rules" do

        describe "with no validation proc specified" do
          before do
            @scss = Sanitize::CSS.new(Sanitize::Config.merge(Sanitize::Config::RELAXED[:css], {
              :at_rules => ['import']
            }))
          end

          it "should allow any URL value" do
            css = %[
              @import url('https://somesite.com/something.css');
            ].strip

            _(@scss.stylesheet(css).strip).must_equal %[
              @import url('https://somesite.com/something.css');
            ].strip
          end
        end

        describe "with a validation proc specified" do
          before do
            google_font_validator = Proc.new { |url| url.start_with?("https://fonts.googleapis.com") }

            @scss = Sanitize::CSS.new(Sanitize::Config.merge(Sanitize::Config::RELAXED[:css], {
              :at_rules => ['import'], :import_url_validator => google_font_validator
            }))
          end

          it "should allow a google fonts url" do
            css = %[
              @import 'https://fonts.googleapis.com/css?family=Indie+Flower';
              @import url('https://fonts.googleapis.com/css?family=Indie+Flower');
            ].strip

            _(@scss.stylesheet(css).strip).must_equal %[
              @import 'https://fonts.googleapis.com/css?family=Indie+Flower';
              @import url('https://fonts.googleapis.com/css?family=Indie+Flower');
            ].strip
          end

          it "should not allow a nasty url" do
            css = %[
              @import 'https://fonts.googleapis.com/css?family=Indie+Flower';
              @import 'https://nastysite.com/nasty_hax0r.css';
              @import url('https://nastysite.com/nasty_hax0r.css');
            ].strip

            _(@scss.stylesheet(css).strip).must_equal %[
              @import 'https://fonts.googleapis.com/css?family=Indie+Flower';
            ].strip
          end

          it "should not allow a blank url" do
            css = %[
              @import 'https://fonts.googleapis.com/css?family=Indie+Flower';
              @import '';
              @import url('');
            ].strip

            _(@scss.stylesheet(css).strip).must_equal %[
              @import 'https://fonts.googleapis.com/css?family=Indie+Flower';
            ].strip
          end
        end
      end
    end
  end
end
