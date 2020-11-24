module Ransack
  module Helpers
    module FormHelper

      # +search_form_for+
      #
      #   <%= search_form_for(@q) do |f| %>
      #
      def search_form_for(record, options = {}, &proc)
        if record.is_a? Ransack::Search
          search = record
          options[:url] ||= polymorphic_path(
            search.klass, format: options.delete(:format)
            )
        elsif record.is_a?(Array) &&
        (search = record.detect { |o| o.is_a?(Ransack::Search) })
          options[:url] ||= polymorphic_path(
            options_for(record), format: options.delete(:format)
            )
        else
          raise ArgumentError,
          'No Ransack::Search object was provided to search_form_for!'
        end
        options[:html] ||= {}
        html_options = {
          class:  html_option_for(options[:class], search),
          id:     html_option_for(options[:id], search),
          method: :get
        }
        options[:as] ||= Ransack.options[:search_key]
        options[:html].reverse_merge!(html_options)
        options[:builder] ||= FormBuilder

        form_for(record, options, &proc)
      end

      # +sort_link+
      #
      #   <%= sort_link(@q, :name, [:name, 'kind ASC'], 'Player Name') %>
      #
      #   You can also use a block:
      #
      #   <%= sort_link(@q, :name, [:name, 'kind ASC']) do %>
      #     <strong>Player Name</strong>
      #   <% end %>
      #
      def sort_link(search_object, attribute, *args, &block)
        search, routing_proxy = extract_search_and_routing_proxy(search_object)
        unless Search === search
          raise TypeError, 'First argument must be a Ransack::Search!'
        end
        args[args.first.is_a?(Array) ? 1 : 0, 0] = capture(&block) if block_given?
        s = SortLink.new(search, attribute, args, params, &block)
        link_to(s.name, url(routing_proxy, s.url_options), s.html_options(args))
      end

      # +sort_url+
      # <%= sort_url(@q, :created_at, default_order: :desc) %>
      #
      def sort_url(search_object, attribute, *args)
        search, routing_proxy = extract_search_and_routing_proxy(search_object)
        unless Search === search
          raise TypeError, 'First argument must be a Ransack::Search!'
        end
        s = SortLink.new(search, attribute, args, params)
        url(routing_proxy, s.url_options)
      end

      private

        def options_for(record)
          record.map { |r| parse_record(r) }
        end

        def parse_record(object)
          return object.klass if object.is_a?(Ransack::Search)
          object
        end

        def html_option_for(option, search)
          return option.to_s if option.present?
          "#{search.klass.to_s.underscore}_search"
        end

        def extract_search_and_routing_proxy(search)
          return [search[1], search[0]] if search.is_a?(Array)
          [search, nil]
        end

        def url(routing_proxy, options_for_url)
          if routing_proxy && respond_to?(routing_proxy)
            send(routing_proxy).url_for(options_for_url)
          else
            url_for(options_for_url)
          end
        end

      class SortLink
        def initialize(search, attribute, args, params)
          @search         = search
          @params         = parameters_hash(params)
          @field          = attribute.to_s
          @sort_fields    = extract_sort_fields_and_mutate_args!(args).compact
          @current_dir    = existing_sort_direction
          @label_text     = extract_label_and_mutate_args!(args)
          @options        = extract_options_and_mutate_args!(args)
          @hide_indicator = @options.delete(:hide_indicator) ||
                            Ransack.options[:hide_sort_order_indicators]
          @default_order  = @options.delete :default_order
        end

        def up_arrow
          Ransack.options[:up_arrow]
        end

        def down_arrow
          Ransack.options[:down_arrow]
        end

        def default_arrow
          Ransack.options[:default_arrow]
        end

        def name
          [ERB::Util.h(@label_text), order_indicator]
          .compact
          .join('&nbsp;'.freeze)
          .html_safe
        end

        def url_options
          @params.merge(
            @options.merge(
              @search.context.search_key => search_and_sort_params))
        end

        def html_options(args)
          html_options = extract_options_and_mutate_args!(args)
          html_options.merge(
            class: [['sort_link'.freeze, @current_dir], html_options[:class]]
                   .compact.join(' '.freeze)
          )
        end

        private

          def parameters_hash(params)
            if ::ActiveRecord::VERSION::MAJOR >= 5 && params.respond_to?(:to_unsafe_h)
              params.to_unsafe_h
            else
              params
            end
          end

          def extract_sort_fields_and_mutate_args!(args)
            return args.shift if args[0].is_a?(Array)
            [@field]
          end

          def extract_label_and_mutate_args!(args)
            return args.shift if args[0].is_a?(String)
            Translate.attribute(@field, context: @search.context)
          end

          def extract_options_and_mutate_args!(args)
            return args.shift.with_indifferent_access if args[0].is_a?(Hash)
            {}
          end

          def search_and_sort_params
            search_params.merge(s: sort_params)
          end

          def search_params
            @params[@search.context.search_key].presence || {}
          end

          def sort_params
            sort_array = recursive_sort_params_build(@sort_fields)
            return sort_array[0] if sort_array.length == 1
            sort_array
          end

          def recursive_sort_params_build(fields)
            return [] if fields.empty?
            [parse_sort(fields[0])] + recursive_sort_params_build(fields.drop 1)
          end

          def parse_sort(field)
            attr_name, new_dir = field.to_s.split(/\s+/)
            if no_sort_direction_specified?(new_dir)
              new_dir = detect_previous_sort_direction_and_invert_it(attr_name)
            end
            "#{attr_name} #{new_dir}"
          end

          def detect_previous_sort_direction_and_invert_it(attr_name)
            if sort_dir = existing_sort_direction(attr_name)
              direction_text(sort_dir)
            else
              default_sort_order(attr_name) || 'asc'.freeze
            end
          end

          def existing_sort_direction(f = @field)
            return unless sort = @search.sorts.detect { |s| s && s.name == f }
            sort.dir
          end

          def default_sort_order(attr_name)
            return @default_order[attr_name] if Hash === @default_order
            @default_order
          end

          def order_indicator
            return if @hide_indicator
            return default_arrow if no_sort_direction_specified?
            if @current_dir == 'desc'.freeze
              up_arrow
            else
              down_arrow
            end
          end

          def no_sort_direction_specified?(dir = @current_dir)
            dir != 'asc'.freeze && dir != 'desc'.freeze
          end

          def direction_text(dir)
            return 'asc'.freeze if dir == 'desc'.freeze
            'desc'.freeze
          end
      end
    end
  end
end
