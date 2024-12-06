# encoding: utf-8
require_relative 'common'

describe 'Sanitize::Transformers::CleanElement' do
  make_my_diffs_pretty!
  parallelize_me!

  strings = {
    :basic => {
      :html       => '<b>Lo<!-- comment -->rem</b> <a href="pants" title="foo" style="text-decoration: underline;">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <style>.foo { color: #fff; }</style> <script>alert("hello world");</script>',
      :default    => 'Lorem ipsum dolor sit amet  ',
      :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sit amet  ',
      :basic      => '<b>Lorem</b> <a href="pants" rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br>amet  ',
      :relaxed    => '<b>Lorem</b> <a href="pants" title="foo" style="text-decoration: underline;">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br>amet <style>.foo { color: #fff; }</style> '
    },

    :malformed => {
      :html       => 'Lo<!-- comment -->rem</b> <a href=pants title="foo>ipsum <a href="http://foo.com/"><strong>dolor</a></strong> sit<br/>amet <script>alert("hello world");',
      :default    => 'Lorem dolor sit amet ',
      :restricted => 'Lorem <strong>dolor</strong> sit amet ',
      :basic      => 'Lorem <a href="pants" rel="nofollow"><strong>dolor</strong></a> sit<br>amet ',
      :relaxed    => 'Lorem <a href="pants" title="foo>ipsum <a href="><strong>dolor</strong></a> sit<br>amet ',
    },

    :unclosed => {
      :html       => '<p>a</p><blockquote>b',
      :default    => ' a  b ',
      :restricted => ' a  b ',
      :basic      => '<p>a</p><blockquote>b</blockquote>',
      :relaxed    => '<p>a</p><blockquote>b</blockquote>'
    },

    :malicious => {
      :html       => '<b>Lo<!-- comment -->rem</b> <a href="javascript:pants" title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br/>amet <<foo>script>alert("hello world");</script>',
      :default    => 'Lorem ipsum dolor sit amet &lt;script&gt;alert("hello world");',
      :restricted => '<b>Lorem</b> ipsum <strong>dolor</strong> sit amet &lt;script&gt;alert("hello world");',
      :basic      => '<b>Lorem</b> <a rel="nofollow">ipsum</a> <a href="http://foo.com/" rel="nofollow"><strong>dolor</strong></a> sit<br>amet &lt;script&gt;alert("hello world");',
      :relaxed    => '<b>Lorem</b> <a title="foo">ipsum</a> <a href="http://foo.com/"><strong>dolor</strong></a> sit<br>amet &lt;script&gt;alert("hello world");'
    }
  }

  protocols = {
    'protocol-based JS injection: simple, no spaces' => {
      :html       => '<a href="javascript:alert(\'XSS\');">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: simple, spaces before' => {
      :html       => '<a href="javascript    :alert(\'XSS\');">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: simple, spaces after' => {
      :html       => '<a href="javascript:    alert(\'XSS\');">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: simple, spaces before and after' => {
      :html       => '<a href="javascript    :   alert(\'XSS\');">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: preceding colon' => {
      :html       => '<a href=":javascript:alert(\'XSS\');">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: UTF-8 encoding' => {
      :html       => '<a href="javascript&#58;">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: long UTF-8 encoding' => {
      :html       => '<a href="javascript&#0058;">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: long UTF-8 encoding without semicolons' => {
      :html       => '<a href=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: hex encoding' => {
      :html       => '<a href="javascript&#x3A;">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: long hex encoding' => {
      :html       => '<a href="javascript&#x003A;">foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: hex encoding without semicolons' => {
      :html       => '<a href=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>foo</a>',
      :default    => 'foo',
      :restricted => 'foo',
      :basic      => '<a rel="nofollow">foo</a>',
      :relaxed    => '<a>foo</a>'
    },

    'protocol-based JS injection: null char' => {
      :html       => "<img src=java\0script:alert(\"XSS\")>",
      :default    => '',
      :restricted => '',
      :basic      => '',
      :relaxed    => '<img>'
    },

    'protocol-based JS injection: invalid URL char' => {
      :html       => '<img src=java\script:alert("XSS")>',
      :default    => '',
      :restricted => '',
      :basic      => '',
      :relaxed    => '<img>'
    },

    'protocol-based JS injection: spaces and entities' => {
      :html       => '<img src=" &#14;  javascript:alert(\'XSS\');">',
      :default    => '',
      :restricted => '',
      :basic      => '',
      :relaxed    => '<img>'
    },

    'protocol whitespace' => {
      :html       => '<a href=" http://example.com/"></a>',
      :default    => '',
      :restricted => '',
      :basic      => '<a href="http://example.com/" rel="nofollow"></a>',
      :relaxed    => '<a href="http://example.com/"></a>'
    }
  }

  describe 'Default config' do
    it 'should remove non-allowlisted elements, leaving safe contents behind' do
      _(Sanitize.fragment('foo <b>bar</b> <strong><a href="#a">baz</a></strong> quux'))
        .must_equal 'foo bar baz quux'

      _(Sanitize.fragment('<script>alert("<xss>");</script>'))
        .must_equal ''

      _(Sanitize.fragment('<<script>script>alert("<xss>");</<script>>'))
        .must_equal '&lt;'

      _(Sanitize.fragment('< script <>> alert("<xss>");</script>'))
        .must_equal '&lt; script &lt;&gt;&gt; alert("");'
    end

    it 'should surround the contents of :whitespace_elements with space characters when removing the element' do
      _(Sanitize.fragment('foo<div>bar</div>baz'))
        .must_equal 'foo bar baz'

      _(Sanitize.fragment('foo<br>bar<br>baz'))
        .must_equal 'foo bar baz'

      _(Sanitize.fragment('foo<hr>bar<hr>baz'))
        .must_equal 'foo bar baz'
    end

    it 'should not choke on several instances of the same element in a row' do
      _(Sanitize.fragment('<img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif"><img src="http://www.google.com/intl/en_ALL/images/logo.gif">'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `iframe` elements' do
      _(Sanitize.fragment('<iframe>hello! <script>alert(0)</script></iframe>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `math` elements' do
      _(Sanitize.fragment('<math>hello! <script>alert(0)</script></math>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `noembed` elements' do
      _(Sanitize.fragment('<noembed>hello! <script>alert(0)</script></noembed>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `noframes` elements' do
      _(Sanitize.fragment('<noframes>hello! <script>alert(0)</script></noframes>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `noscript` elements' do
      _(Sanitize.fragment('<noscript>hello! <script>alert(0)</script></noscript>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `plaintext` elements' do
      _(Sanitize.fragment('<plaintext>hello! <script>alert(0)</script>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `script` elements' do
      _(Sanitize.fragment('<script>hello! <script>alert(0)</script></script>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `style` elements' do
      _(Sanitize.fragment('<style>hello! <script>alert(0)</script></style>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `svg` elements' do
      _(Sanitize.fragment('<svg>hello! <script>alert(0)</script></svg>'))
        .must_equal ''
    end

    it 'should not preserve the content of removed `xmp` elements' do
      _(Sanitize.fragment('<xmp>hello! <script>alert(0)</script></xmp>'))
        .must_equal ''
    end

    strings.each do |name, data|
      it "should clean #{name} HTML" do
        _(Sanitize.fragment(data[:html])).must_equal(data[:default])
      end
    end

    protocols.each do |name, data|
      it "should not allow #{name}" do
        _(Sanitize.fragment(data[:html])).must_equal(data[:default])
      end
    end
  end

  describe 'Restricted config' do
    before do
      @s = Sanitize.new(Sanitize::Config::RESTRICTED)
    end

    strings.each do |name, data|
      it "should clean #{name} HTML" do
        _(@s.fragment(data[:html])).must_equal(data[:restricted])
      end
    end

    protocols.each do |name, data|
      it "should not allow #{name}" do
        _(@s.fragment(data[:html])).must_equal(data[:restricted])
      end
    end
  end

  describe 'Basic config' do
    before do
      @s = Sanitize.new(Sanitize::Config::BASIC)
    end

    it 'should not choke on valueless attributes' do
      _(@s.fragment('foo <a href>foo</a> bar'))
        .must_equal 'foo <a href="" rel="nofollow">foo</a> bar'
    end

    it 'should downcase attribute names' do
      _(@s.fragment('<a HREF="javascript:alert(\'foo\')">bar</a>'))
        .must_equal '<a rel="nofollow">bar</a>'
    end

    strings.each do |name, data|
      it "should clean #{name} HTML" do
        _(@s.fragment(data[:html])).must_equal(data[:basic])
      end
    end

    protocols.each do |name, data|
      it "should not allow #{name}" do
        _(@s.fragment(data[:html])).must_equal(data[:basic])
      end
    end
  end

  describe 'Relaxed config' do
    before do
      @s = Sanitize.new(Sanitize::Config::RELAXED)
    end

    it 'should encode special chars in attribute values' do
      _(@s.fragment('<a href="http://example.com" title="<b>&eacute;xamples</b> & things">foo</a>'))
        .must_equal '<a href="http://example.com" title="<b>éxamples</b> &amp; things">foo</a>'
    end

    strings.each do |name, data|
      it "should clean #{name} HTML" do
        _(@s.fragment(data[:html])).must_equal(data[:relaxed])
      end
    end

    protocols.each do |name, data|
      it "should not allow #{name}" do
        _(@s.fragment(data[:html])).must_equal(data[:relaxed])
      end
    end
  end

  describe 'Custom configs' do
    it 'should allow attributes on all elements if allowlisted under :all' do
      input = '<p class="foo">bar</p>'

      _(Sanitize.fragment(input)).must_equal ' bar '

      _(Sanitize.fragment(input, {
        :elements   => ['p'],
        :attributes => {:all => ['class']}
      })).must_equal input

      _(Sanitize.fragment(input, {
        :elements   => ['p'],
        :attributes => {'div' => ['class']}
      })).must_equal '<p>bar</p>'

      _(Sanitize.fragment(input, {
        :elements   => ['p'],
        :attributes => {'p' => ['title'], :all => ['class']}
      })).must_equal input
    end

    it "should not allow relative URLs when relative URLs aren't allowlisted" do
      input = '<a href="/foo/bar">Link</a>'

      _(Sanitize.fragment(input,
        :elements   => ['a'],
        :attributes => {'a' => ['href']},
        :protocols  => {'a' => {'href' => ['http']}}
      )).must_equal '<a>Link</a>'
    end

    it 'should allow relative URLs containing colons when the colon is not in the first path segment' do
      input = '<a href="/wiki/Special:Random">Random Page</a>'

      _(Sanitize.fragment(input, {
        :elements   => ['a'],
        :attributes => {'a' => ['href']},
        :protocols  => {'a' => {'href' => [:relative]}}
      })).must_equal input
    end

    it 'should allow relative URLs containing colons when the colon is part of an anchor' do
      input = '<a href="#fn:1">Footnote 1</a>'

      _(Sanitize.fragment(input, {
        :elements   => ['a'],
        :attributes => {'a' => ['href']},
        :protocols  => {'a' => {'href' => [:relative]}}
      })).must_equal input

      input = '<a href="somepage#fn:1">Footnote 1</a>'

      _(Sanitize.fragment(input, {
        :elements   => ['a'],
        :attributes => {'a' => ['href']},
        :protocols  => {'a' => {'href' => [:relative]}}
      })).must_equal input
    end

    it 'should remove the contents of filtered nodes when :remove_contents is true' do
      _(Sanitize.fragment('foo bar <div>baz<span>quux</span></div>',
        :remove_contents => true
      )).must_equal 'foo bar   '
    end

    it 'should remove the contents of specified nodes when :remove_contents is an Array or Set of element names as strings' do
      _(Sanitize.fragment('foo bar <div>baz<span>quux</span> <b>hi</b><script>alert("hello!");</script></div>',
        :remove_contents => ['script', 'span']
      )).must_equal 'foo bar  baz hi '

      _(Sanitize.fragment('foo bar <div>baz<span>quux</span> <b>hi</b><script>alert("hello!");</script></div>',
        :remove_contents => Set.new(['script', 'span'])
      )).must_equal 'foo bar  baz hi '
    end

    it 'should remove the contents of specified nodes when :remove_contents is an Array or Set of element names as symbols' do
      _(Sanitize.fragment('foo bar <div>baz<span>quux</span> <b>hi</b><script>alert("hello!");</script></div>',
        :remove_contents => [:script, :span]
      )).must_equal 'foo bar  baz hi '

      _(Sanitize.fragment('foo bar <div>baz<span>quux</span> <b>hi</b><script>alert("hello!");</script></div>',
        :remove_contents => Set.new([:script, :span])
      )).must_equal 'foo bar  baz hi '
    end

    it 'should remove the contents of allowlisted iframes' do
      _(Sanitize.fragment('<iframe>hi <script>hello</script></iframe>',
        :elements => ['iframe']
      )).must_equal '<iframe></iframe>'
    end

    it 'should not allow arbitrary HTML5 data attributes by default' do
      _(Sanitize.fragment('<b data-foo="bar"></b>',
        :elements => ['b']
      )).must_equal '<b></b>'

      _(Sanitize.fragment('<b class="foo" data-foo="bar"></b>',
        :attributes => {'b' => ['class']},
        :elements   => ['b']
      )).must_equal '<b class="foo"></b>'
    end

    it 'should allow arbitrary HTML5 data attributes when the :attributes config includes :data' do
      s = Sanitize.new(
        :attributes => {'b' => [:data]},
        :elements   => ['b']
      )

      _(s.fragment('<b data-foo="valid" data-bar="valid"></b>'))
        .must_equal '<b data-foo="valid" data-bar="valid"></b>'

      _(s.fragment('<b data-="invalid"></b>'))
        .must_equal '<b></b>'

      _(s.fragment('<b data-="invalid"></b>'))
        .must_equal '<b></b>'

      _(s.fragment('<b data-xml="invalid"></b>'))
        .must_equal '<b></b>'

      _(s.fragment('<b data-xmlfoo="invalid"></b>'))
        .must_equal '<b></b>'

      _(s.fragment('<b data-f:oo="valid"></b>'))
        .must_equal '<b></b>'

      _(s.fragment('<b data-f/oo="partial"></b>'))
        .must_equal '<b data-f=""></b>' # Nokogiri quirk; not ideal, but harmless

      _(s.fragment('<b data-éfoo="valid"></b>'))
        .must_equal '<b></b>' # Another annoying Nokogiri quirk.
    end

    it 'should replace whitespace_elements with configured :before and :after values' do
      s = Sanitize.new(
        :whitespace_elements => {
          'p'   => { :before => "\n", :after => "\n" },
          'div' => { :before => "\n", :after => "\n" },
          'br'  => { :before => "\n", :after => "\n" },
        }
      )

      _(s.fragment('<p>foo</p>')).must_equal "\nfoo\n"
      _(s.fragment('<p>foo</p><p>bar</p>')).must_equal "\nfoo\n\nbar\n"
      _(s.fragment('foo<div>bar</div>baz')).must_equal "foo\nbar\nbaz"
      _(s.fragment('foo<br>bar<br>baz')).must_equal "foo\nbar\nbaz"
    end

    it 'should handle protocols correctly regardless of case' do
      input = '<a href="hTTpS://foo.com/">Text</a>'

      _(Sanitize.fragment(input, {
        :elements   => ['a'],
        :attributes => {'a' => ['href']},
        :protocols  => {'a' => {'href' => ['https']}}
      })).must_equal input

      input = '<a href="mailto:someone@example.com?Subject=Hello">Text</a>'

      _(Sanitize.fragment(input, {
        :elements   => ['a'],
        :attributes => {'a' => ['href']},
        :protocols  => {'a' => {'href' => ['https']}}
      })).must_equal "<a>Text</a>"
    end

    it 'should sanitize protocols in data attributes even if data attributes are generically allowed' do
      input = '<a data-url="mailto:someone@example.com">Text</a>'

      _(Sanitize.fragment(input, {
        :elements => ['a'],
        :attributes => {'a' => [:data]},
        :protocols => {'a' => {'data-url' => ['https']}}
      })).must_equal "<a>Text</a>"

      _(Sanitize.fragment(input, {
        :elements => ['a'],
        :attributes => {'a' => [:data]},
        :protocols => {'a' => {'data-url' => ['mailto']}}
      })).must_equal input
    end

    it 'should prevent `<meta>` tags from being used to set a non-UTF-8 charset' do
      _(Sanitize.document('<html><head><meta charset="utf-8"></head><body>Howdy!</body></html>',
        :elements   => %w[html head meta body],
        :attributes => {'meta' => ['charset']}
      )).must_equal "<html><head><meta charset=\"utf-8\"></head><body>Howdy!</body></html>"

      _(Sanitize.document('<html><meta charset="utf-8">Howdy!</html>',
        :elements   => %w[html meta],
        :attributes => {'meta' => ['charset']}
      )).must_equal "<html><meta charset=\"utf-8\">Howdy!</html>"

      _(Sanitize.document('<html><meta charset="us-ascii">Howdy!</html>',
        :elements   => %w[html meta],
        :attributes => {'meta' => ['charset']}
      )).must_equal "<html><meta charset=\"utf-8\">Howdy!</html>"

      _(Sanitize.document('<html><meta http-equiv="content-type" content=" text/html; charset=us-ascii">Howdy!</html>',
        :elements   => %w[html meta],
        :attributes => {'meta' => %w[content http-equiv]}
      )).must_equal "<html><meta http-equiv=\"content-type\" content=\" text/html;charset=utf-8\">Howdy!</html>"

      _(Sanitize.document('<html><meta http-equiv="Content-Type" content="text/plain;charset = us-ascii">Howdy!</html>',
        :elements   => %w[html meta],
        :attributes => {'meta' => %w[content http-equiv]}
      )).must_equal "<html><meta http-equiv=\"Content-Type\" content=\"text/plain;charset=utf-8\">Howdy!</html>"
    end

    it 'should not modify `<meta>` tags that already set a UTF-8 charset' do
      _(Sanitize.document('<html><head><meta http-equiv="Content-Type" content="text/html;charset=utf-8"></head><body>Howdy!</body></html>',
        :elements   => %w[html head meta body],
        :attributes => {'meta' => %w[content http-equiv]}
      )).must_equal "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\"></head><body>Howdy!</body></html>"
    end

    it 'always removes `<noscript>` elements even if `noscript` is in the allowlist' do
      assert_equal(
        '',
        Sanitize.fragment('<noscript>foo</noscript>', elements: ['noscript'])
      )
    end

  end
end
