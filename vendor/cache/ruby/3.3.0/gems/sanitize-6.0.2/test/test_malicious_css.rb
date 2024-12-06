# encoding: utf-8
require_relative 'common'

# Miscellaneous attempts to sneak maliciously crafted CSS past Sanitize. Some of
# these are courtesy of (or inspired by) the OWASP XSS Filter Evasion Cheat
# Sheet.
#
# https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet

describe 'Malicious CSS' do
  make_my_diffs_pretty!
  parallelize_me!

  before do
    @s = Sanitize::CSS.new(Sanitize::Config::RELAXED)
  end

  it 'should not be possible to inject an expression by munging it with a comment' do
    _(@s.properties(%[width:expr/*XSS*/ession(alert('XSS'))])).
      must_equal ''

    _(@s.properties(%[width:ex/*XSS*//*/*/pression(alert("XSS"))])).
      must_equal ''
  end

  it 'should not be possible to inject an expression by munging it with a newline' do
    _(@s.properties(%[width:\nexpression(alert('XSS'));])).
      must_equal ''
  end

  it 'should not allow the javascript protocol' do
    _(@s.properties(%[background-image:url("javascript:alert('XSS')");])).
      must_equal ''

    _(Sanitize.fragment(%[<div style="background-image: url(&#1;javascript:alert('XSS'))">],
      Sanitize::Config::RELAXED)).must_equal '<div></div>'
  end

  it 'should not allow behaviors' do
    _(@s.properties(%[behavior: url(xss.htc);])).must_equal ''
  end

  describe 'sanitization bypass via CSS at-rule in HTML <style> element' do
    before do
      @s = Sanitize.new(Sanitize::Config::RELAXED)
    end

    it 'is not possible to prematurely end a <style> element' do
      assert_equal(
        %[<style>@media<\\/style><iframe srcdoc='<script>alert(document.domain)<\\/script>'>{}</style>],
        @s.fragment(%[<style>@media</sty/**/le><iframe srcdoc='<script>alert(document.domain)</script>'></style>])
      )
    end
  end
end
