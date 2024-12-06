# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  class InheritableHash < Hash
    def initialize(parent=nil)
      @parent = parent
    end

    def [](k)
      value = super
      return value if own_keys.include?(k)

      value || parent[k]
    end

    def parent
      @parent ||= {}
    end

    def include?(k)
      super or parent.include?(k)
    end

    def each(&b)
      keys.each do |k|
        b.call(k, self[k])
      end
    end

    alias own_keys keys
    def keys
      keys = own_keys.concat(parent.keys)
      keys.uniq!
      keys
    end
  end

  class InheritableList
    include Enumerable

    def initialize(parent=nil)
      @parent = parent
    end

    def parent
      @parent ||= []
    end

    def each(&b)
      return enum_for(:each) unless block_given?

      parent.each(&b)
      own_entries.each(&b)
    end

    def own_entries
      @own_entries ||= []
    end

    def push(o)
      own_entries << o
    end
    alias << push
  end

  # shared methods for some indentation-sensitive lexers
  module Indentation
    def reset!
      super
      @block_state = @block_indentation = nil
    end

    # push a state for the next indented block
    def starts_block(block_state)
      @block_state = block_state
      @block_indentation = @last_indentation || ''
      puts "    starts_block: #{block_state.inspect}" if @debug
      puts "    block_indentation: #{@block_indentation.inspect}" if @debug
    end

    # handle a single indented line
    def indentation(indent_str)
      puts "    indentation: #{indent_str.inspect}" if @debug
      puts "    block_indentation: #{@block_indentation.inspect}" if @debug
      @last_indentation = indent_str

      # if it's an indent and we know where to go next,
      # push that state.  otherwise, push content and
      # clear the block state.
      if (@block_state &&
          indent_str.start_with?(@block_indentation) &&
          indent_str != @block_indentation
      )
        push @block_state
      else
        @block_state = @block_indentation = nil
        push :content
      end
    end
  end
end
