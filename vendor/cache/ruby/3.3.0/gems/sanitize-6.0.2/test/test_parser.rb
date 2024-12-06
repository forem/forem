# encoding: utf-8
require_relative 'common'

describe 'Parser' do
  make_my_diffs_pretty!
  parallelize_me!

  it 'should translate valid entities into characters' do
    _(Sanitize.fragment("&apos;&eacute;&amp;")).must_equal("'é&amp;")
  end

  it 'should translate orphaned ampersands into entities' do
    _(Sanitize.fragment('at&t')).must_equal('at&amp;t')
  end

  it 'should not add newlines after tags when serializing a fragment' do
    _(Sanitize.fragment("<div>foo\n\n<p>bar</p><div>\nbaz</div></div><div>quux</div>", :elements => ['div', 'p']))
      .must_equal "<div>foo\n\n<p>bar</p><div>\nbaz</div></div><div>quux</div>"
  end

  it 'should not have the Nokogiri 1.4.2+ unterminated script/style element bug' do
    _(Sanitize.fragment('foo <script>bar')).must_equal 'foo '
    _(Sanitize.fragment('foo <style>bar')).must_equal 'foo '
  end

  it 'ambiguous non-tag brackets like "1 > 2 and 2 < 1" should be parsed correctly' do
    _(Sanitize.fragment('1 > 2 and 2 < 1')).must_equal '1 &gt; 2 and 2 &lt; 1'
    _(Sanitize.fragment('OMG HAPPY BIRTHDAY! *<:-D')).must_equal 'OMG HAPPY BIRTHDAY! *&lt;:-D'
  end

  describe 'when siblings are added after a node during traversal' do
    it 'the added siblings should be traversed' do
      html = %[
        <div id="one">
            <div id="one_one">
                <div id="one_one_one"></div>
            </div>
            <div id="one_two"></div>
        </div>
        <div id="two">
            <div id="two_one"><div id="two_one_one"></div></div>
            <div id="two_two"></div>
        </div>
        <div id="three"></div>
      ]

      siblings = []

      Sanitize.fragment(html, :transformers => ->(env) {
          name = env[:node].name

          if name == 'div'
            env[:node].add_next_sibling('<b id="added_' + env[:node]['id'] + '">')
          elsif name == 'b'
            siblings << env[:node][:id]
          end

          return {:node_allowlist => [env[:node]]}
      })

      # All siblings should be traversed, and in the order added.
      _(siblings).must_equal [
        "added_one_one_one",
        "added_one_one",
        "added_one_two",
        "added_one",
        "added_two_one_one",
        "added_two_one",
        "added_two_two",
        "added_two",
        "added_three"
      ]
    end
  end
end
