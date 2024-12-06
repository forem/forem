# frozen_string_literal: true

require 'forwardable'

module Capybara
  ##
  # A {Capybara::Result} represents a collection of {Capybara::Node::Element} on the page. It is possible to interact with this
  # collection similar to an Array because it implements Enumerable and offers the following Array methods through delegation:
  #
  # * \[\]
  # * each()
  # * at()
  # * size()
  # * count()
  # * length()
  # * first()
  # * last()
  # * empty?()
  # * values_at()
  # * sample()
  #
  # @see Capybara::Node::Element
  #
  class Result
    include Enumerable
    extend Forwardable

    def initialize(elements, query)
      @elements = elements
      @result_cache = []
      @filter_errors = []
      @results_enum = lazy_select_elements { |node| query.matches_filters?(node, @filter_errors) }
      @query = query
      @allow_reload = false
    end

    def_delegators :full_results, :size, :length, :last, :values_at, :inspect, :sample

    alias index find_index

    def each(&block)
      return enum_for(:each) unless block

      @result_cache.each(&block)
      loop do
        next_result = @results_enum.next
        add_to_cache(next_result)
        yield next_result
      end
      self
    end

    def [](*args)
      idx, length = args
      max_idx = case idx
      when Integer
        if idx.negative?
          nil
        else
          length.nil? ? idx : idx + length - 1
        end
      when Range
        # idx.max is broken with beginless ranges
        # idx.end && idx.max # endless range will have end == nil
        max = idx.end
        max = nil if max&.negative?
        max -= 1 if max && idx.exclude_end?
        max
      end

      if max_idx.nil?
        full_results[*args]
      else
        load_up_to(max_idx + 1)
        @result_cache[*args]
      end
    end
    alias :at :[]

    def empty?
      !any?
    end

    def compare_count
      return 0 unless @query

      count, min, max, between = @query.options.values_at(:count, :minimum, :maximum, :between)

      # Only check filters for as many elements as necessary to determine result
      if count && (count = Integer(count))
        return load_up_to(count + 1) <=> count
      end

      return -1 if min && (min = Integer(min)) && (load_up_to(min) < min)

      return 1 if max && (max = Integer(max)) && (load_up_to(max + 1) > max)

      if between
        min, max = (between.begin && between.min) || 1, between.end
        max -= 1 if max && between.exclude_end?

        size = load_up_to(max ? max + 1 : min)
        return size <=> min unless between.include?(size)
      end

      0
    end

    def matches_count?
      compare_count.zero?
    end

    def failure_message
      message = @query.failure_message
      if count.zero?
        message << ' but there were no matches'
      else
        message << ", found #{count} #{Capybara::Helpers.declension('match', 'matches', count)}: " \
                << full_results.map(&:text).map(&:inspect).join(', ')
      end
      unless rest.empty?
        elements = rest.map { |el| el.text rescue '<<ERROR>>' }.map(&:inspect).join(', ') # rubocop:disable Style/RescueModifier
        message << '. Also found ' << elements << ', which matched the selector but not all filters. '
        message << @filter_errors.join('. ') if (rest.size == 1) && count.zero?
      end
      message
    end

    def negative_failure_message
      failure_message.sub(/(to find)/, 'not \1')
    end

    def unfiltered_size
      @elements.length
    end

    ##
    # @api private
    #
    def allow_reload!
      @allow_reload = true
      self
    end

  private

    def add_to_cache(elem)
      elem.allow_reload!(@result_cache.size) if @allow_reload
      @result_cache << elem
    end

    def load_up_to(num)
      loop do
        break if @result_cache.size >= num

        add_to_cache(@results_enum.next)
      end
      @result_cache.size
    end

    def full_results
      loop { @result_cache << @results_enum.next }
      @result_cache
    end

    def rest
      @rest ||= @elements - full_results
    end

    if RUBY_PLATFORM == 'java'
      # JRuby < 9.2.8.0 has an issue with lazy enumerators which
      # causes a concurrency issue with network requests here
      # https://github.com/jruby/jruby/issues/4212
      # while JRuby >= 9.2.8.0 leaks threads when using lazy enumerators
      # https://github.com/teamcapybara/capybara/issues/2349
      # so disable the use and JRuby users will need to pay a performance penalty
      def lazy_select_elements(&block)
        @elements.select(&block).to_enum # non-lazy evaluation
      end
    else
      def lazy_select_elements(&block)
        @elements.lazy.select(&block)
      end
    end
  end
end
