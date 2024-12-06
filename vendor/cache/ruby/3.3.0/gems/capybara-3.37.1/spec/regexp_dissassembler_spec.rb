# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara::Selector::RegexpDisassembler, :aggregate_failures do
  it 'handles strings' do
    verify_strings(
      /abcdef/ => %w[abcdef],
      /abc def/ => ['abc def']
    )
  end

  it 'handles escaped characters' do
    verify_strings(
      /abc\\def/ => %w[abc\def],
      /abc\.def/ => %w[abc.def],
      /\nabc/ => ["\nabc"],
      %r{abc/} => %w[abc/],
      /ab\++cd/ => %w[ab+ cd]
    )
  end

  it 'handles wildcards' do
    verify_strings(
      /abc.*def/ => %w[abc def],
      /.*def/ => %w[def],
      /abc./ => %w[abc],
      /abc.*/ => %w[abc],
      /abc.def/ => %w[abc def],
      /abc.def.ghi/ => %w[abc def ghi],
      /abc.abcd.abcde/ => %w[abcde],
      /.*/ => []
    )
  end

  it 'ignores optional characters for substrings' do
    {
      /abc*def/ => %w[ab def],
      /abc*/ => %w[ab],
      /c*/ => [],
      /abc?def/ => %w[ab def],
      /abc?/ => %w[ab],
      /abc?def?/ => %w[ab de],
      /abc?def?g/ => %w[ab de g],
      /d?/ => []
    }.each do |regexp, expected|
      expect(described_class.new(regexp).substrings).to eq expected
    end
  end

  it 'handles optional characters for #alternated_substrings' do
    verify_alternated_strings(
      {
        /abc*def/ => [%w[ab def]],
        /abc*/ => [%w[ab]],
        /c*/ => [],
        /abc?def/ => [%w[abdef], %w[abcdef]],
        /abc?/ => [%w[ab]],
        /abc?def?/ => [%w[abde], %w[abcde]],
        /abc?def?g/ => [%w[abdeg], %w[abdefg], %w[abcdeg], %w[abcdefg]],
        /d?/ => []
      }
    )
  end

  it 'handles character classes' do
    verify_strings(
      /abc[a-z]/ => %w[abc],
      /abc[a-z]def[0-9]g/ => %w[abc def g],
      /[0-9]abc/ => %w[abc],
      /[0-9]+/ => [],
      /abc[0-9&&[^7]]/ => %w[abc]
    )
  end

  it 'handles posix bracket expressions' do
    verify_strings(
      /abc[[:alpha:]]/ => %w[abc],
      /[[:digit:]]abc/ => %w[abc],
      /abc[[:print:]]def/ => %w[abc def]
    )
  end

  it 'handles repitition' do
    verify_strings(
      /abc{3}/ => %w[abccc],
      /abc{3}d/ => %w[abcccd],
      /abc{0}/ => %w[ab],
      /abc{,2}/ => %w[ab],
      /abc{2,}/ => %w[abcc],
      /def{1,5}/ => %w[def],
      /abc+def/ => %w[abc def],
      /ab(cde){,4}/ => %w[ab],
      /(ab){,2}cd/ => %w[cd],
      /(abc){2,3}/ => %w[abcabc],
      /(abc){3}/ => %w[abcabcabc],
      /ab{2,3}cd/ => %w[abb cd],
      /(ab){2,3}cd/ => %w[abab cd]
    )
  end

  it 'handles non-greedy repetition' do
    verify_strings(
      /abc.*?/ => %w[abc],
      /abc+?/ => %w[abc],
      /abc*?cde/ => %w[ab cde],
      /(abc)+?def/ => %w[abc def],
      /ab(cde)*?fg/ => %w[ab fg]
    )
  end

  it 'ignores alternation for #substrings' do
    {
      /abc|def/ => [],
      /ab(?:c|d)/ => %w[ab],
      /ab(c|d|e)fg/ => %w[ab fg],
      /ab?(c|d)fg/ => %w[a fg],
      /ab(c|d)ef/ => %w[ab ef],
      /ab(cd?|ef)g/ => %w[ab g],
      /ab(cd|ef*)g/ => %w[ab g],
      /ab|cd*/ => [],
      /cd(?:ef|gh)|xyz/ => [],
      /(cd(?:ef|gh)|xyz)/ => [],
      /cd(ef|gh)+/ => %w[cd],
      /cd(ef|gh)?/ => %w[cd],
      /cd(ef|gh)?ij/ => %w[cd ij],
      /cd(ef|gh)+ij/ => %w[cd ij],
      /cd(ef|gh){2}ij/ => %w[cd ij],
      /(cd(ef|g*))/ => %w[cd],
      /ab(cd){0,2}ef/ => %w[ab ef],
      /ab(cd){0,1}ef/ => %w[ab ef],
      /ab(cd|cd)ef/ => %w[ab ef],
      /ab(cd|cd)?ef/ => %w[ab ef],
      /ab\\?cd/ => %w[ab cd]
    }.each do |regexp, expected|
      expect(described_class.new(regexp).substrings).to eq expected
    end
  end

  it 'handles alternation for #alternated_substrings' do
    verify_alternated_strings(
      {
        /abc|def/ => [%w[abc], %w[def]],
        /ab(?:c|d)/ => [%w[abc], %w[abd]],
        /ab(c|d|e)fg/ => [%w[abcfg], %w[abdfg], %w[abefg]],
        /ab?(c|d)fg/ => [%w[acfg], %w[adfg], %w[abcfg], %w[abdfg]],
        /ab(c|d)ef/ => [%w[abcef], %w[abdef]],
        /ab(cd?|ef)g/ => [%w[abcg], %w[abcdg], %w[abefg]],
        /ab(cd|ef*)g/ => [%w[abcdg], %w[abe g]],
        /ab|cd*/ => [%w[ab], %w[c]],
        /cd(?:ef|gh)|xyz/ => [%w[cdef], %w[cdgh], %w[xyz]],
        /(cd(?:ef|gh)|xyz)/ => [%w[cdef], %w[cdgh], %w[xyz]],
        /cd(ef|gh)+/ => [%w[cdef], %w[cdgh]],
        /cd(ef|gh)?/ => [%w[cd]],
        /cd(ef|gh)?ij/ => [%w[cdij], %w[cdefij], %w[cdghij]],
        /cd(ef|gh)+ij/ => [%w[cdef ij], %w[cdgh ij]],
        /cd(ef|gh){2}ij/ => [%w[cdefefij], %w[cdefghij], %w[cdghefij], %w[cdghghij]],
        /(cd(ef|g*))/ => [%w[cd]],
        /a|b*/ => [],
        /ab(?:c|d?)/ => [%w[ab]],
        /ab(c|d)|a*/ => [],
        /(abc)?(d|e)/ => [%w[d], %w[e]],
        /(abc*de)?(d|e)/ => [%w[d], %w[e]],
        /(abc*de)?(d|e?)/ => [],
        /(abc)?(d|e?)/ => [],
        /ab(cd){0,2}ef/ => [%w[ab ef]],
        /ab(cd){0,1}ef/ => [%w[abef], %w[abcdef]],
        /ab(cd|cd)ef/ => [%w[abcdef]],
        /ab(cd|cd)?ef/ => [%w[abef], %w[abcdef]],
        /ab\\?cd/ => [%w[abcd], %w[ab\cd]]
      }
    )
  end

  it 'handles grouping' do
    verify_strings(
      /(abc)/ => %w[abc],
      /(abc)?/ => [],
      /ab(cde)/ => %w[abcde],
      /(abc)de/ => %w[abcde],
      /ab(cde)fg/ => %w[abcdefg],
      /ab(?<name>cd)ef/ => %w[abcdef],
      /gh(?>ij)kl/ => %w[ghijkl],
      /m(n.*p)q/ => %w[mn pq],
      /(?:ab(cd)*){2,3}/ => %w[ab],
      /(ab(cd){3})?/ => [],
      /(ab(cd)+){2}/ => %w[abcd]
    )
  end

  it 'handles meta characters' do
    verify_strings(
      /abc\d/ => %w[abc],
      /abc\wdef/ => %w[abc def],
      /\habc/ => %w[abc]
    )
  end

  it 'handles character properties' do
    verify_strings(
      /ab\p{Alpha}cd/ => %w[ab cd],
      /ab\p{Blank}/ => %w[ab],
      /\p{Digit}cd/ => %w[cd]
    )
  end

  it 'handles backreferences' do
    verify_strings(
      /a(?<group>abc).\k<group>.+/ => %w[aabc]
    )
  end

  it 'handles subexpressions' do
    verify_strings(
      /\A(?<paren>a\g<paren>*b)+\z/ => %w[a b]
    )
  end

  it 'ignores negative lookaheads' do
    verify_strings(
      /^(?!.*\bContributing Editor\b).*$/ => %w[],
      /abc(?!.*def).*/ => %w[abc],
      /(?!.*def)abc/ => %w[abc],
      /abc(?!.*def.*).*ghi/ => %w[abc ghi],
      /abc(?!.*bcd)def/ => %w[abcdef]
    )
  end

  it 'handles anchors' do
    verify_strings(
      /^abc/ => %w[abc],
      /def$/ => %w[def],
      /^abc$/ => %w[abc]
    )
  end

  def verify_strings(hsh)
    hsh.each do |regexp, expected|
      expect(Capybara::Selector::RegexpDisassembler.new(regexp).substrings).to eq expected
    end
    verify_alternated_strings(hsh, wrap: true)
  end

  def verify_alternated_strings(hsh, wrap: false)
    hsh.each do |regexp, expected|
      expected = [expected] if wrap && (expected != [])
      expect(Capybara::Selector::RegexpDisassembler.new(regexp).alternated_substrings).to eq expected
    end
  end
end
