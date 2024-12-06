require 'ransack/constants'
require 'ransack/predicate'

module Ransack
  module Configuration

    mattr_accessor :predicates, :options

    class PredicateCollection
      attr_reader :sorted_names_with_underscores

      def initialize
        @collection = {}
        @sorted_names_with_underscores = []
      end

      delegate :[], :keys, :has_key?, to: :@collection

      def []=(key, value)
        @sorted_names_with_underscores << [key, '_' + key]
        @sorted_names_with_underscores.sort! { |(a, _), (b, _)| b.length <=> a.length }

        @collection[key] = value
      end
    end

    self.predicates = PredicateCollection.new

    self.options = {
      :search_key => :q,
      :ignore_unknown_conditions => true,
      :hide_sort_order_indicators => false,
      :up_arrow => '&#9660;'.freeze,
      :down_arrow => '&#9650;'.freeze,
      :default_arrow => nil,
      :sanitize_scope_args => true,
      :postgres_fields_sort_option => nil,
      :strip_whitespace => true
    }

    def configure
      yield self
    end

    def add_predicate(name, opts = {})
      name = name.to_s
      opts[:name] = name
      compounds = opts.delete(:compounds)
      compounds = true if compounds.nil?
      compounds = false if opts[:wants_array]

      self.predicates[name] = Predicate.new(opts)

      Constants::SUFFIXES.each do |suffix|
        compound_name = name + suffix
        self.predicates[compound_name] = Predicate.new(
          opts.merge(
            :name => compound_name,
            :arel_predicate => arel_predicate_with_suffix(
              opts[:arel_predicate], suffix
              ),
            :compound => true
          )
        )
      end if compounds
    end

    # The default `search_key` name is `:q`. The default key may be overridden
    # in an initializer file like `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Name the search_key `:query` instead of the default `:q`
    #   config.search_key = :query
    # end
    #
    # Sometimes there are situations when the default search parameter name
    # cannot be used, for instance if there were two searches on one page.
    # Another name can be set using the `search_key` option with Ransack
    # `ransack`, `search` and `@search_form_for` methods in controllers & views.
    #
    # In the controller:
    # @search = Log.ransack(params[:log_search], search_key: :log_search)
    #
    # In the view:
    # <%= f.search_form_for @search, as: :log_search %>
    #
    def search_key=(name)
      self.options[:search_key] = name
    end

    # By default Ransack ignores errors if an unknown predicate, condition or
    # attribute is passed into a search. The default may be overridden in an
    # initializer file like `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Raise if an unknown predicate, condition or attribute is passed
    #   config.ignore_unknown_conditions = false
    # end
    #
    def ignore_unknown_conditions=(boolean)
      self.options[:ignore_unknown_conditions] = boolean
    end

    # By default, Ransack displays sort order indicator arrows with HTML codes:
    #
    #   up_arrow:   '&#9660;'
    #   down_arrow: '&#9650;'
    #
    # There is also a default arrow which is displayed if a column is not sorted.
    # By default this is nil so nothing will be displayed.
    #
    # Any of the defaults may be globally overridden in an initializer file
    # like `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Globally set the up arrow to an icon, and the down and default arrows to unicode.
    #   config.custom_arrows = {
    #     up_arrow:   '<i class="fa fa-long-arrow-up"></i>',
    #     down_arrow: 'U+02193',
    #     default_arrow: 'U+11047'
    #   }
    # end
    #
    def custom_arrows=(opts = {})
      self.options[:up_arrow] = opts[:up_arrow].freeze if opts[:up_arrow]
      self.options[:down_arrow] = opts[:down_arrow].freeze if opts[:down_arrow]
      self.options[:default_arrow] = opts[:default_arrow].freeze if opts[:default_arrow]
    end

    # Ransack sanitizes many values in your custom scopes into booleans.
    # [1, '1', 't', 'T', 'true', 'TRUE'] all evaluate to true.
    # [0, '0', 'f', 'F', 'false', 'FALSE'] all evaluate to false.
    #
    # This default may be globally overridden in an initializer file like
    # `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Accept my custom scope values as what they are.
    #   config.sanitize_custom_scope_booleans = false
    # end
    #
    def sanitize_custom_scope_booleans=(boolean)
      self.options[:sanitize_scope_args] = boolean
    end

    # The `NULLS FIRST` and `NULLS LAST` options can be used to determine
    # whether nulls appear before or after non-null values in the sort ordering.
    #
    # User may want to configure it like this:
    #
    # Ransack.configure do |c|
    #   c.postgres_fields_sort_option = :nulls_first # or e.g. :nulls_always_last
    # end
    #
    # See this feature: https://www.postgresql.org/docs/13/queries-order.html
    #
    def postgres_fields_sort_option=(setting)
      self.options[:postgres_fields_sort_option] = setting
    end

    # By default, Ransack displays sort order indicator arrows in sort links.
    # The default may be globally overridden in an initializer file like
    # `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Hide sort link order indicators globally across the application
    #   config.hide_sort_order_indicators = true
    # end
    #
    def hide_sort_order_indicators=(boolean)
      self.options[:hide_sort_order_indicators] = boolean
    end

    # By default, Ransack displays strips all whitespace when searching for a string.
    # The default may be globally changed in an initializer file like
    # `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Enable whitespace stripping for string searches
    #   config.strip_whitespace = true
    # end
    #
    def strip_whitespace=(boolean)
      self.options[:strip_whitespace] = boolean
    end

    def arel_predicate_with_suffix(arel_predicate, suffix)
      if arel_predicate === Proc
        proc { |v| "#{arel_predicate.call(v)}#{suffix}" }
      else
        "#{arel_predicate}#{suffix}"
      end
    end

  end
end
