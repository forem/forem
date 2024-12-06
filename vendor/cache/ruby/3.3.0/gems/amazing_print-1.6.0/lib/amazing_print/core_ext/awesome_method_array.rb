# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
#
# The following makes it possible to invoke amazing_print while performing
# operations on method arrays, ex:
#
#   ap [].methods - Object.methods
#   ap ''.methods.grep(/!|\?/)
#
# If you could think of a better way please let me know :-)
#
module AwesomeMethodArray # :nodoc:
  def -(other)
    super.tap do |arr|
      arr.instance_variable_set(:@__awesome_methods__, instance_variable_get(:@__awesome_methods__))
    end
  end

  def &(other)
    super.tap do |arr|
      arr.instance_variable_set(:@__awesome_methods__, instance_variable_get(:@__awesome_methods__))
    end
  end

  #
  # Intercepting Array#grep needs a special treatment since grep accepts
  # an optional block.
  #
  def grep(pattern, &blk)
    #
    # The following looks rather insane and I've sent numerous hours trying
    # to figure it out. The problem is that if grep gets called with the
    # block, for example:
    #
    #    [].methods.grep(/(.+?)_by/) { $1.to_sym }
    #
    # ...then simple:
    #
    #    original_grep(pattern, &blk)
    #
    # doesn't set $1 within the grep block which causes nil.to_sym failure.
    # The workaround below has been tested with Ruby 1.8.7/Rails 2.3.8 and
    # Ruby 1.9.2/Rails 3.0.0. For more info see the following thread dating
    # back to 2003 when Ruby 1.8.0 was as fresh off the grill as Ruby 1.9.2
    # is in 2010 :-)
    #
    # http://www.justskins.com/forums/bug-when-rerouting-string-52852.html
    #
    # BTW, if you figure out a better way of intercepting Array#grep please
    # let me know: twitter.com/mid -- or just say hi so I know you've read
    # the comment :-)
    #
    arr = if blk
            super(pattern) do |match|
              #
              # The binding can only be used with Ruby-defined methods, therefore
              # we must rescue potential "ArgumentError: Can't create Binding from
              # C level Proc" error.
              #
              # For example, the following raises ArgumentError since #succ method
              # is defined in C.
              #
              # [ 0, 1, 2, 3, 4 ].grep(1..2, &:succ)
              #
              begin
                eval("%Q/#{match.to_s.gsub('/', '\/')}/ =~ #{pattern.inspect}", blk.binding, __FILE__, __LINE__)
              rescue StandardError
                ArgumentError
              end
              yield match
            end
          else
            super(pattern)
          end
    arr.instance_variable_set(:@__awesome_methods__, instance_variable_get(:@__awesome_methods__))
    arr.select! { |item| item.is_a?(Symbol) || item.is_a?(String) } # grep block might return crap.
    arr
  end
end
