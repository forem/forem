# encoding: utf-8
require_relative 'common'

# Miscellaneous attempts to sneak maliciously crafted HTML past Sanitize. Many
# of these are courtesy of (or inspired by) the OWASP XSS Filter Evasion Cheat
# Sheet.
#
# https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet

describe 'Malicious HTML' do
  make_my_diffs_pretty!
  parallelize_me!

  before do
    @s = Sanitize.new(Sanitize::Config::RELAXED)
  end

  describe 'comments' do
    it 'should not allow script injection via conditional comments' do
      _(@s.fragment(%[<!--[if gte IE 4]>\n<script>alert('XSS');</script>\n<![endif]-->])).
        must_equal ''
    end
  end

  describe 'interpolation (ERB, PHP, etc.)' do
    it 'should escape ERB-style tags' do
      _(@s.fragment('<% naughty_ruby_code %>')).
        must_equal '&lt;% naughty_ruby_code %&gt;'

      _(@s.fragment('<%= naughty_ruby_code %>')).
        must_equal '&lt;%= naughty_ruby_code %&gt;'
    end

    it 'should remove PHP-style tags' do
      _(@s.fragment('<? naughtyPHPCode(); ?>')).
        must_equal ''

      _(@s.fragment('<?= naughtyPHPCode(); ?>')).
        must_equal ''
    end
  end

  describe '<body>' do
    it 'should not be possible to inject JS via a malformed event attribute' do
      _(@s.document('<html><head></head><body onload!#$%&()*~+-_.,:;?@[/|\\]^`=alert("XSS")></body></html>')).
        must_equal "<html><head></head><body></body></html>"
    end
  end

  describe '<iframe>' do
    it 'should not be possible to inject an iframe using an improperly closed tag' do
      _(@s.fragment(%[<iframe src=http://ha.ckers.org/scriptlet.html <])).
        must_equal ''
    end
  end

  describe '<img>' do
    it 'should not be possible to inject JS via an unquoted <img> src attribute' do
      _(@s.fragment("<img src=javascript:alert('XSS')>")).must_equal '<img>'
    end

    it 'should not be possible to inject JS using grave accents as <img> src delimiters' do
      _(@s.fragment("<img src=`javascript:alert('XSS')`>")).must_equal '<img>'
    end

    it 'should not be possible to inject <script> via a malformed <img> tag' do
      _(@s.fragment('<img """><script>alert("XSS")</script>">')).
        must_equal '<img>"&gt;'
    end

    it 'should not be possible to inject protocol-based JS' do
      _(@s.fragment('<img src=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>')).
        must_equal '<img>'

      _(@s.fragment('<img src=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>')).
        must_equal '<img>'

      _(@s.fragment('<img src=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>')).
        must_equal '<img>'

      # Encoded tab character.
      _(@s.fragment(%[<img src="jav&#x09;ascript:alert('XSS');">])).
        must_equal '<img>'

      # Encoded newline.
      _(@s.fragment(%[<img src="jav&#x0A;ascript:alert('XSS');">])).
        must_equal '<img>'

      # Encoded carriage return.
      _(@s.fragment(%[<img src="jav&#x0D;ascript:alert('XSS');">])).
        must_equal '<img>'

      # Null byte.
      _(@s.fragment(%[<img src=java\0script:alert("XSS")>])).
        must_equal '<img>'

      # Spaces plus meta char.
      _(@s.fragment(%[<img src=" &#14;  javascript:alert('XSS');">])).
        must_equal '<img>'

      # Mixed spaces and tabs.
      _(@s.fragment(%[<img src="j\na v\tascript://alert('XSS');">])).
        must_equal '<img>'
    end

    it 'should not be possible to inject protocol-based JS via whitespace' do
      _(@s.fragment(%[<img src="jav\tascript:alert('XSS');">])).
        must_equal '<img>'
    end

    it 'should not be possible to inject JS using a half-open <img> tag' do
      _(@s.fragment(%[<img src="javascript:alert('XSS')"])).
        must_equal ''
    end
  end

  describe '<script>' do
    it 'should not be possible to inject <script> using a malformed non-alphanumeric tag name' do
      _(@s.fragment(%[<script/xss src="http://ha.ckers.org/xss.js">alert(1)</script>])).
        must_equal ''
    end

    it 'should not be possible to inject <script> via extraneous open brackets' do
      _(@s.fragment(%[<<script>alert("XSS");//<</script>])).
        must_equal '&lt;'
    end
  end

  # libxml2 >= 2.9.2 doesn't escape comments within some attributes, in an
  # attempt to preserve server-side includes. This can result in XSS since an
  # unescaped double quote can allow an attacker to inject a non-allowlisted
  # attribute. Sanitize works around this by implementing its own escaping for
  # affected attributes.
  #
  # The relevant libxml2 code is here:
  # <https://github.com/GNOME/libxml2/commit/960f0e275616cadc29671a218d7fb9b69eb35588>
  describe 'unsafe libxml2 server-side includes in attributes' do
    using_unpatched_libxml2 = Nokogiri::VersionInfo.instance.libxml2_using_system?

    tag_configs = [
      {
        tag_name: 'a',
        escaped_attrs: %w[ action href src name ],
        unescaped_attrs: []
      },

      {
        tag_name: 'div',
        escaped_attrs: %w[ action href src ],
        unescaped_attrs: %w[ name ]
      }
    ]

    before do
      @s = Sanitize.new({
        elements: %w[ a div ],

        attributes: {
          all: %w[ action href src name ]
        }
      })
    end

    tag_configs.each do |tag_config|
      tag_name = tag_config[:tag_name]

      tag_config[:escaped_attrs].each do |attr_name|
        input = %[<#{tag_name} #{attr_name}='examp<!--" onmouseover=alert(1)>-->le.com'>foo</#{tag_name}>]

        it 'should escape unsafe characters in attributes' do
          skip "behavior should only exist in nokogiri's patched libxml" if using_unpatched_libxml2

          # This uses Nokogumbo's HTML-compliant serializer rather than
          # libxml2's.
          _(@s.fragment(input)).
            must_equal(%[<#{tag_name} #{attr_name}="examp<!--%22%20onmouseover=alert(1)>-->le.com">foo</#{tag_name}>])

          # This uses the not-quite-standards-compliant libxml2 serializer via
          # Nokogiri, so the output may be a little different as of Nokogiri
          # 1.10.2 when using Nokogiri's vendored libxml2 due to this patch:
          # https://github.com/sparklemotion/nokogiri/commit/4852e43cb6039e26d8c51af78621e539cbf46c5d
          fragment = Nokogiri::HTML.fragment(input)
          @s.node!(fragment)
          _(fragment.to_html).
            must_equal(%[<#{tag_name} #{attr_name}="examp&lt;!--%22%20onmouseover=alert(1)&gt;--&gt;le.com">foo</#{tag_name}>])
        end

        it 'should round-trip to the same output' do
          output = @s.fragment(input)
          _(@s.fragment(output)).must_equal(output)
        end
      end

      tag_config[:unescaped_attrs].each do |attr_name|
        input = %[<#{tag_name} #{attr_name}='examp<!--" onmouseover=alert(1)>-->le.com'>foo</#{tag_name}>]

        it 'should not escape characters unnecessarily' do
          skip "behavior should only exist in nokogiri's patched libxml" if using_unpatched_libxml2

          # This uses Nokogumbo's HTML-compliant serializer rather than
          # libxml2's.
          _(@s.fragment(input)).
            must_equal(%[<#{tag_name} #{attr_name}="examp<!--&quot; onmouseover=alert(1)>-->le.com">foo</#{tag_name}>])

          # This uses the not-quite-standards-compliant libxml2 serializer via
          # Nokogiri, so the output may be a little different as of Nokogiri
          # 1.10.2 when using Nokogiri's vendored libxml2 due to this patch:
          # https://github.com/sparklemotion/nokogiri/commit/4852e43cb6039e26d8c51af78621e539cbf46c5d
          fragment = Nokogiri::HTML.fragment(input)
          @s.node!(fragment)
          _(fragment.to_html).
            must_equal(%[<#{tag_name} #{attr_name}='examp&lt;!--" onmouseover=alert(1)&gt;--&gt;le.com'>foo</#{tag_name}>])
        end

        it 'should round-trip to the same output' do
          output = @s.fragment(input)
          _(@s.fragment(output)).must_equal(output)
        end
      end
    end
  end

  # https://github.com/rgrove/sanitize/security/advisories/GHSA-p4x4-rw2p-8j8m
  describe 'foreign content bypass in relaxed config' do
    it 'prevents a sanitization bypass via carefully crafted foreign content' do
      %w[iframe noembed noframes noscript plaintext script style xmp].each do |tag_name|
        _(@s.fragment(%[<math><#{tag_name}>/*&lt;/#{tag_name}&gt;&lt;img src onerror=alert(1)>*/])).
          must_equal ''

        _(@s.fragment(%[<svg><#{tag_name}>/*&lt;/#{tag_name}&gt;&lt;img src onerror=alert(1)>*/])).
          must_equal ''
      end
    end
  end

  # These tests cover an unsupported and unsafe custom config that allows MathML
  # and SVG elements, which Sanitize's docs specifically say multiple times in
  # big prominent warnings that you SHOULD NOT DO because Sanitize doesn't
  # support MathML or SVG.
  #
  # Do not use the custom configs you see in these tests! If you do, you may be
  # creating XSS vulnerabilities in your application.
  describe 'foreign content bypass in unsafe custom config that allows MathML or SVG' do
    unescaped_content_elements = %w[
      noembed
      noframes
      plaintext
      script
      xmp
    ]

    removed_content_elements = %w[
      iframe
    ]

    removed_elements = %w[
      noscript
      style
    ]

    before do
      @s = Sanitize.new(
        Sanitize::Config.merge(
          Sanitize::Config::RELAXED,
          elements: Sanitize::Config::RELAXED[:elements] +
            unescaped_content_elements +
            removed_content_elements +
            %w[math svg]
        )
      )
    end

    unescaped_content_elements.each do |name|
      it "forcibly escapes text content inside `<#{name}>` in a MathML namespace" do
        assert_equal(
          "<math><#{name}>&lt;img src=x onerror=alert(1)&gt;</#{name}></math>",
          @s.fragment("<math><#{name}>&lt;img src=x onerror=alert(1)&gt;</#{name}>")
        )
      end

      it "forcibly escapes text content inside `<#{name}>` in an SVG namespace" do
        assert_equal(
          "<svg><#{name}>&lt;img src=x onerror=alert(1)&gt;</#{name}></svg>",
          @s.fragment("<svg><#{name}>&lt;img src=x onerror=alert(1)&gt;</#{name}>")
        )
      end
    end

    removed_content_elements.each do |name|
      it "removes text content inside `<#{name}>` in a MathML namespace" do
        assert_equal(
          "<math><#{name}></#{name}></math>",
          @s.fragment("<math><#{name}>&lt;img src=x onerror=alert(1)&gt;</#{name}>")
        )
      end

      it "removes text content inside `<#{name}>` in an SVG namespace" do
        assert_equal(
          "<svg><#{name}></#{name}></svg>",
          @s.fragment("<svg><#{name}>&lt;img src=x onerror=alert(1)&gt;</#{name}>")
        )
      end
    end

    removed_elements.each do |name|
      it "removes `<#{name}>` elements in a MathML namespace" do
        assert_equal(
          '<math></math>',
          @s.fragment("<math><#{name}>&lt;img src=x onerror=alert(1)&gt;</#{name}>")
        )
      end

      it "removes `<#{name}>` elements in an SVG namespace" do
        assert_equal(
          '<svg></svg>',
          @s.fragment("<svg><#{name}>&lt;img src=x onerror=alert(1)&gt;</#{name}>")
        )
      end
    end
  end

  describe 'sanitization bypass by exploiting scripting-disabled <noscript> behavior' do
    before do
      @s = Sanitize.new(
        Sanitize::Config.merge(
          Sanitize::Config::RELAXED,
          elements: Sanitize::Config::RELAXED[:elements] + ['noscript']
        )
      )
    end

    it 'is prevented by removing `<noscript>` elements regardless of the allowlist' do
      assert_equal(
        '',
        @s.fragment(%[<noscript><div id='</noscript>&lt;img src=x onerror=alert(1)&gt; '>])
      )
    end
  end
end
