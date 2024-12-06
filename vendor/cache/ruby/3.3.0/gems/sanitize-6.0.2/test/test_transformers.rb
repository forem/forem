# encoding: utf-8
require_relative 'common'

describe 'Transformers' do
  make_my_diffs_pretty!
  parallelize_me!

  it 'should receive a complete env Hash as input' do
    Sanitize.fragment('<SPAN>foo</SPAN>',
      :foo => :bar,
      :transformers => lambda {|env|
        return unless env[:node].element?

        _(env[:config][:foo]).must_equal :bar
        _(env[:is_allowlisted]).must_equal false
        _(env[:is_whitelisted]).must_equal env[:is_allowlisted]
        _(env[:node]).must_be_kind_of Nokogiri::XML::Node
        _(env[:node_name]).must_equal 'span'
        _(env[:node_allowlist]).must_be_kind_of Set
        _(env[:node_allowlist]).must_be_empty
        _(env[:node_whitelist]).must_equal env[:node_allowlist]
      }
    )
  end

  it 'should traverse all node types, including the fragment itself' do
    nodes = []

    Sanitize.fragment('<div>foo</div><!--bar--><script>cdata!</script>',
      :transformers => proc {|env| nodes << env[:node_name] }
    )

    _(nodes).must_equal %w[
      #document-fragment div text text text comment script text
    ]
  end

  it 'should perform top-down traversal' do
    nodes = []

    Sanitize.fragment('<div><span><strong>foo</strong></span><b></b></div><p>bar</p>',
      :transformers => proc {|env| nodes << env[:node_name] if env[:node].element? }
    )

    _(nodes).must_equal %w[div span strong b p]
  end

  it 'should allowlist nodes in the node allowlist' do
    _(Sanitize.fragment('<div class="foo">foo</div><span>bar</span>',
      :transformers => [
        proc {|env|
          {:node_allowlist => [env[:node]]} if env[:node_name] == 'div'
        },

        proc {|env|
          _(env[:is_allowlisted]).must_equal false unless env[:node_name] == 'div'
          _(env[:is_allowlisted]).must_equal true if env[:node_name] == 'div'
          _(env[:node_allowlist]).must_include env[:node] if env[:node_name] == 'div'
          _(env[:is_whitelisted]).must_equal env[:is_allowlisted]
          _(env[:node_whitelist]).must_equal env[:node_allowlist]
        }
      ]
    )).must_equal '<div class="foo">foo</div>bar'
  end

  it 'should clear the node allowlist after each fragment' do
    called = false

    Sanitize.fragment('<div>foo</div>',
      :transformers => proc {|env| {:node_allowlist => [env[:node]]}}
    )

    Sanitize.fragment('<div>foo</div>',
      :transformers => proc {|env|
        called = true
        _(env[:is_allowlisted]).must_equal false
        _(env[:is_whitelisted]).must_equal env[:is_allowlisted]
        _(env[:node_allowlist]).must_be_empty
        _(env[:node_whitelist]).must_equal env[:node_allowlist]
      }
    )

    _(called).must_equal true
  end

  it 'should accept a method transformer' do
    def transformer(env); end
    _(Sanitize.fragment('<div>foo</div>', :transformers => method(:transformer)))
      .must_equal(' foo ')
  end

  describe 'Image allowlist transformer' do
    require 'uri'

    image_allowlist_transformer = lambda do |env|
      # Ignore everything except <img> elements.
      return unless env[:node_name] == 'img'

      node      = env[:node]
      image_uri = URI.parse(node['src'])

      # Only allow relative URLs or URLs with the example.com domain. The
      # image_uri.host.nil? check ensures that protocol-relative URLs like
      # "//evil.com/foo.jpg".
      unless image_uri.host == 'example.com' || (image_uri.host.nil? && image_uri.relative?)
        node.unlink # `Nokogiri::XML::Node#unlink` removes a node from the document
      end
    end

    before do
      @s = Sanitize.new(Sanitize::Config.merge(Sanitize::Config::RELAXED,
          :transformers => image_allowlist_transformer))
    end

    it 'should allow images with relative URLs' do
      input = '<img src="/foo/bar.jpg">'
      _(@s.fragment(input)).must_equal(input)
    end

    it 'should allow images at the example.com domain' do
      input = '<img src="http://example.com/foo/bar.jpg">'
      _(@s.fragment(input)).must_equal(input)

      input = '<img src="https://example.com/foo/bar.jpg">'
      _(@s.fragment(input)).must_equal(input)

      input = '<img src="//example.com/foo/bar.jpg">'
      _(@s.fragment(input)).must_equal(input)
    end

    it 'should not allow images at other domains' do
      input = '<img src="http://evil.com/foo/bar.jpg">'
      _(@s.fragment(input)).must_equal('')

      input = '<img src="https://evil.com/foo/bar.jpg">'
      _(@s.fragment(input)).must_equal('')

      input = '<img src="//evil.com/foo/bar.jpg">'
      _(@s.fragment(input)).must_equal('')

      input = '<img src="http://subdomain.example.com/foo/bar.jpg">'
      _(@s.fragment(input)).must_equal('')
    end
  end

  describe 'YouTube transformer' do
    youtube_transformer = lambda do |env|
      node      = env[:node]
      node_name = env[:node_name]

      # Don't continue if this node is already allowlisted or is not an element.
      return if env[:is_allowlisted] || !node.element?

      # Don't continue unless the node is an iframe.
      return unless node_name == 'iframe'

      # Verify that the video URL is actually a valid YouTube video URL.
      return unless node['src'] =~ %r|\A(?:https?:)?//(?:www\.)?youtube(?:-nocookie)?\.com/|

      # We're now certain that this is a YouTube embed, but we still need to run
      # it through a special Sanitize step to ensure that no unwanted elements or
      # attributes that don't belong in a YouTube embed can sneak in.
      Sanitize.node!(node, {
        :elements => %w[iframe],

        :attributes => {
          'iframe'  => %w[allowfullscreen frameborder height src width]
        }
      })

      # Now that we're sure that this is a valid YouTube embed and that there are
      # no unwanted elements or attributes hidden inside it, we can tell Sanitize
      # to allowlist the current node.
      {:node_allowlist => [node]}
    end

    it 'should allow HTTP YouTube video embeds' do
      input = '<iframe width="420" height="315" src="http://www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen bogus="bogus"><script>alert()</script></iframe>'

      _(Sanitize.fragment(input, :transformers => youtube_transformer))
        .must_equal '<iframe width="420" height="315" src="http://www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen=""></iframe>'
    end

    it 'should allow HTTPS YouTube video embeds' do
      input = '<iframe width="420" height="315" src="https://www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen bogus="bogus"><script>alert()</script></iframe>'

      _(Sanitize.fragment(input, :transformers => youtube_transformer))
        .must_equal '<iframe width="420" height="315" src="https://www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen=""></iframe>'
    end

    it 'should allow protocol-relative YouTube video embeds' do
      input = '<iframe width="420" height="315" src="//www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen bogus="bogus"><script>alert()</script></iframe>'

      _(Sanitize.fragment(input, :transformers => youtube_transformer))
        .must_equal '<iframe width="420" height="315" src="//www.youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen=""></iframe>'
    end

    it 'should allow privacy-enhanced YouTube video embeds' do
      input = '<iframe width="420" height="315" src="https://www.youtube-nocookie.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen bogus="bogus"><script>alert()</script></iframe>'

      _(Sanitize.fragment(input, :transformers => youtube_transformer))
        .must_equal '<iframe width="420" height="315" src="https://www.youtube-nocookie.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen=""></iframe>'
    end

    it 'should not allow non-YouTube video embeds' do
      input = '<iframe width="420" height="315" src="http://www.fake-youtube.com/embed/QH2-TGUlwu4" frameborder="0" allowfullscreen></iframe>'

      _(Sanitize.fragment(input, :transformers => youtube_transformer))
        .must_equal('')
    end
  end

  describe 'DOM modification transformer' do
    b_to_strong_tag_transformer = lambda do |env|
      node      = env[:node]
      node_name = env[:node_name]

      if node_name == 'b'
        node.name = 'strong'
      end
    end

    it 'should allow the <b> tag to be changed to a <strong> tag' do
      input = '<b>text</b>'

      _(Sanitize.fragment(input, :elements => ['strong'], :transformers => b_to_strong_tag_transformer))
        .must_equal '<strong>text</strong>'
    end
  end
end
