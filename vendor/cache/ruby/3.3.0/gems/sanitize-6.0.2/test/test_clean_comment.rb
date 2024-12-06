# encoding: utf-8
require_relative 'common'

describe 'Sanitize::Transformers::CleanComment' do
  make_my_diffs_pretty!
  parallelize_me!

  describe 'when :allow_comments is false' do
    before do
      @s = Sanitize.new(:allow_comments => false, :elements => ['div'])
    end

    it 'should remove comments' do
      _(@s.fragment('foo <!-- comment --> bar')).must_equal 'foo  bar'
      _(@s.fragment('foo <!-- ')).must_equal 'foo '
      _(@s.fragment('foo <!-- - -> bar')).must_equal 'foo '
      _(@s.fragment("foo <!--\n\n\n\n-->bar")).must_equal 'foo bar'
      _(@s.fragment("foo <!-- <!-- <!-- --> --> -->bar")).must_equal 'foo  --&gt; --&gt;bar'
      _(@s.fragment("foo <div <!-- comment -->>bar</div>")).must_equal 'foo <div>&gt;bar</div>'

      # Special case: the comment markup is inside a <script>, which makes it
      # text content and not an actual HTML comment.
      _(@s.fragment("<script><!-- comment --></script>")).must_equal ''

      _(Sanitize.fragment("<script><!-- comment --></script>", :allow_comments => false, :elements => ['script']))
        .must_equal '<script><!-- comment --></script>'
    end
  end

  describe 'when :allow_comments is true' do
    before do
      @s = Sanitize.new(:allow_comments => true, :elements => ['div'])
    end

    it 'should allow comments' do
      _(@s.fragment('foo <!-- comment --> bar')).must_equal 'foo <!-- comment --> bar'
      _(@s.fragment('foo <!-- ')).must_equal 'foo <!-- -->'
      _(@s.fragment('foo <!-- - -> bar')).must_equal 'foo <!-- - -> bar-->'
      _(@s.fragment("foo <!--\n\n\n\n-->bar")).must_equal "foo <!--\n\n\n\n-->bar"
      _(@s.fragment("foo <!-- <!-- <!-- --> --> -->bar")).must_equal 'foo <!-- <!-- <!-- --> --&gt; --&gt;bar'
      _(@s.fragment("foo <div <!-- comment -->>bar</div>")).must_equal 'foo <div>&gt;bar</div>'

      _(Sanitize.fragment("<script><!-- comment --></script>", :allow_comments => true, :elements => ['script']))
        .must_equal '<script><!-- comment --></script>'
    end
  end
end
