# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown-parser-gfm which is licensed under the MIT.
#++
#

module Kramdown
  module Options

    define(:hard_wrap, Boolean, true, <<~EOF)
      Interprets line breaks literally

      Insert HTML `<br />` tags inside paragraphs where the original Markdown
      document had newlines (by default, Markdown ignores these newlines).

      Default: true
      Used by: GFM parser
    EOF

    define(:gfm_quirks, Object, [:paragraph_end], <<~EOF) do |val|
      Enables a set of GFM specific quirks

      The way how GFM is transformed on Github often differs from the way
      kramdown does things. Many of these differences are negligible but
      others are not.

      This option allows one to enable/disable certain GFM quirks, i.e. ways
      in which GFM parsing differs from kramdown parsing.

      The value has to be a list of quirk names that should be enabled,
      separated by commas. Possible names are:

      * paragraph_end

        Disables the kramdown restriction that at least one blank line has to
        be used after a paragraph before a new block element can be started.

        Note that if this quirk is used, lazy line wrapping does not fully
        work anymore!

      * no_auto_typographic

        Disables automatic conversion of some characters into their
        corresponding typographic symbols (like `--` to em-dash etc).
        This helps to achieve results closer to what GitHub Flavored
        Markdown produces.

      Default: paragraph_end
      Used by: GFM parser
    EOF
      val = simple_array_validator(val, :gfm_quirks)
      val.map! { |v| str_to_sym(v.to_s) }
      val
    end

  end
end
