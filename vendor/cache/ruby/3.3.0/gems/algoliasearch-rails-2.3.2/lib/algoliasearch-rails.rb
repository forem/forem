require 'algolia'

require 'algoliasearch/version'
require 'algoliasearch/utilities'

if defined? Rails
  begin
    require 'algoliasearch/railtie'
  rescue LoadError
  end
end

begin
  require 'active_job'
rescue LoadError
  # no queue support, fine
end

require 'logger'

module AlgoliaSearch

  class NotConfigured < StandardError; end
  class BadConfiguration < StandardError; end
  class NoBlockGiven < StandardError; end
  class MixedSlavesAndReplicas < StandardError; end

  autoload :Configuration, 'algoliasearch/configuration'
  extend Configuration

  autoload :Pagination, 'algoliasearch/pagination'

  class << self
    attr_reader :included_in

    def included(klass)
      @included_in ||= []
      @included_in << klass
      @included_in.uniq!

      klass.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

  end

  class IndexSettings
    DEFAULT_BATCH_SIZE = 1000

    # AlgoliaSearch settings
    OPTIONS = [
      # Attributes
      :searchableAttributes, :attributesForFaceting, :unretrievableAttributes, :attributesToRetrieve,
      # Ranking
      :ranking, :customRanking, :relevancyStrictness, # Replicas are handled via `add_replica`
      # Faceting
      :maxValuesPerFacet, :sortFacetValuesBy,
      # Highlighting / Snippeting
      :attributesToHighlight, :attributesToSnippet, :highlightPreTag, :highlightPostTag,
      :snippetEllipsisText, :restrictHighlightAndSnippetArrays,
      # Pagination
      :hitsPerPage, :paginationLimitedTo,
      # Typo
      :minWordSizefor1Typo, :minWordSizefor2Typos, :typoTolerance, :allowTyposOnNumericTokens,
      :disableTypoToleranceOnAttributes, :disableTypoToleranceOnWords, :separatorsToIndex,
      # Language
      :ignorePlurals, :removeStopWords, :camelCaseAttributes, :decompoundedAttributes,
      :keepDiacriticsOnCharacters, :queryLanguages, :indexLanguages,
      # Query Rules
      :enableRules,
      # Query Strategy
      :queryType, :removeWordsIfNoResults, :advancedSyntax, :optionalWords,
      :disablePrefixOnAttributes, :disableExactOnAttributes, :exactOnSingleWordQuery, :alternativesAsExact,
      # Performance
      :numericAttributesForFiltering, :allowCompressionOfIntegerArray,
      # Advanced
      :attributeForDistinct, :distinct, :replaceSynonymsInHighlight, :minProximity, :responseFields,
      :maxFacetHits,

      # Rails-specific
      :synonyms, :placeholders, :altCorrections,
    ]
    OPTIONS.each do |k|
      define_method k do |v|
        instance_variable_set("@#{k}", v)
      end
    end

    def initialize(options, &block)
      @options = options
      instance_exec(&block) if block_given?
    end

    def use_serializer(serializer)
      @serializer = serializer
      # instance_variable_set("@serializer", serializer)
    end

    def attribute(*names, &block)
      raise ArgumentError.new('Cannot pass multiple attribute names if block given') if block_given? and names.length > 1
      raise ArgumentError.new('Cannot specify additional attributes on a replica index') if @options[:replica]
      @attributes ||= {}
      names.flatten.each do |name|
        @attributes[name.to_s] = block_given? ? Proc.new { |o| o.instance_eval(&block) } : Proc.new { |o| o.send(name) }
      end
    end
    alias :attributes :attribute

    def add_attribute(*names, &block)
      raise ArgumentError.new('Cannot pass multiple attribute names if block given') if block_given? and names.length > 1
      raise ArgumentError.new('Cannot specify additional attributes on a replica index') if @options[:replica]
      @additional_attributes ||= {}
      names.each do |name|
        @additional_attributes[name.to_s] = block_given? ? Proc.new { |o| o.instance_eval(&block) } : Proc.new { |o| o.send(name) }
      end
    end
    alias :add_attributes :add_attribute

    def is_mongoid?(object)
      defined?(::Mongoid::Document) && object.class.include?(::Mongoid::Document)
    end

    def is_sequel?(object)
      defined?(::Sequel) && defined?(::Sequel::Model) && object.class < ::Sequel::Model
    end

    def is_active_record?(object)
      !is_mongoid?(object) && !is_sequel?(object)
    end

    def get_default_attributes(object)
      if is_mongoid?(object)
        # work-around mongoid 2.4's unscoped method, not accepting a block
        object.attributes
      elsif is_sequel?(object)
        object.to_hash
      else
        object.class.unscoped do
          object.attributes
        end
      end
    end

    def get_attribute_names(object)
      get_attributes(object).keys
    end

    def attributes_to_hash(attributes, object)
      if attributes
        Hash[attributes.map { |name, value| [name.to_s, value.call(object) ] }]
      else
        {}
      end
    end

    def get_attributes(object)
      # If a serializer is set, we ignore attributes
      # everything should be done via the serializer
      if not @serializer.nil?
        attributes = @serializer.new(object).attributes
      else
        if @attributes.nil? || @attributes.length == 0
          # no `attribute ...` have been configured, use the default attributes of the model
          attributes = get_default_attributes(object)
        else
          # at least 1 `attribute ...` has been configured, therefore use ONLY the one configured
          if is_active_record?(object)
            object.class.unscoped do
              attributes = attributes_to_hash(@attributes, object)
            end
          else
            attributes = attributes_to_hash(@attributes, object)
          end
        end
      end

      attributes.merge!(attributes_to_hash(@additional_attributes, object)) if @additional_attributes

      if @options[:sanitize]
        sanitizer = begin
          ::HTML::FullSanitizer.new
        rescue NameError
          # from rails 4.2
          ::Rails::Html::FullSanitizer.new
        end
        attributes = sanitize_attributes(attributes, sanitizer)
      end

      if @options[:force_utf8_encoding] && Object.const_defined?(:RUBY_VERSION) && RUBY_VERSION.to_f > 1.8
        attributes = encode_attributes(attributes)
      end

      attributes
    end

    def sanitize_attributes(v, sanitizer)
      case v
      when String
        sanitizer.sanitize(v)
      when Hash
        v.each { |key, value| v[key] = sanitize_attributes(value, sanitizer) }
      when Array
        v.map { |x| sanitize_attributes(x, sanitizer) }
      else
        v
      end
    end

    def encode_attributes(v)
      case v
      when String
        v.dup.force_encoding('utf-8')
      when Hash
        v.each { |key, value| v[key] = encode_attributes(value) }
      when Array
        v.map { |x| encode_attributes(x) }
      else
        v
      end
    end

    def geoloc(lat_attr = nil, lng_attr = nil, &block)
      raise ArgumentError.new('Cannot specify additional attributes on a replica index') if @options[:replica]
      add_attribute :_geoloc do |o|
        block_given? ? o.instance_eval(&block) : { :lat => o.send(lat_attr).to_f, :lng => o.send(lng_attr).to_f }
      end
    end

    def tags(*args, &block)
      raise ArgumentError.new('Cannot specify additional attributes on a replica index') if @options[:replica]
      add_attribute :_tags do |o|
        v = block_given? ? o.instance_eval(&block) : args
        v.is_a?(Array) ? v : [v]
      end
    end

    def get_setting(name)
      instance_variable_get("@#{name}")
    end

    def to_settings
      settings = {}
      OPTIONS.each do |k|
        v = get_setting(k)
        settings[k] = v if !v.nil?
      end

      if !@options[:replica]
        settings[:replicas] = additional_indexes.select { |opts, s| opts[:replica] }.map do |opts, s|
          name = opts[:index_name]
          name = "#{name}_#{Rails.env.to_s}" if opts[:per_environment]
          name = "virtual(#{name})" if opts[:virtual]
          name
        end
        settings.delete(:replicas) if settings[:replicas].empty?
      end
      settings
    end

    def add_index(index_name, options = {}, &block)
      raise ArgumentError.new('Cannot specify additional index on a replica index') if @options[:replica]
      raise ArgumentError.new('No block given') if !block_given?
      raise ArgumentError.new('Options auto_index and auto_remove cannot be set on nested indexes') if options[:auto_index] || options[:auto_remove]
      @additional_indexes ||= {}
      options[:index_name] = index_name
      @additional_indexes[options] = IndexSettings.new(options, &block)
    end

    def add_replica(index_name, options = {}, &block)
      raise ArgumentError.new('Cannot specify additional replicas on a replica index') if @options[:replica]
      raise ArgumentError.new('No block given') if !block_given?
      add_index(index_name, options.merge({ :replica => true, :primary_settings => self }), &block)
    end

    def additional_indexes
      @additional_indexes || {}
    end
  end

  # Default queueing system
  if defined?(::ActiveJob::Base)
    # lazy load the ActiveJob class to ensure the
    # queue is initialized before using it
    # see https://github.com/algolia/algoliasearch-rails/issues/69
    autoload :AlgoliaJob, 'algoliasearch/algolia_job'
  end

  # this class wraps an Algolia::Index object ensuring all raised exceptions
  # are correctly logged or thrown depending on the `raise_on_failure` option
  class SafeIndex
    def initialize(name, raise_on_failure)
      @index = AlgoliaSearch.client.init_index(name)
      @raise_on_failure = raise_on_failure.nil? || raise_on_failure
    end

    ::Algolia::Search::Index.instance_methods(false).each do |m|
      define_method(m) do |*args, &block|
        SafeIndex.log_or_throw(m, @raise_on_failure) do
          @index.send(m, *args, &block)
        end
      end
    end

    # special handling of wait_task to handle null task_id
    def wait_task(task_id)
      return if task_id.nil? && !@raise_on_failure # ok
      SafeIndex.log_or_throw(:wait_task, @raise_on_failure) do
        @index.wait_task(task_id)
      end
    end

    # special handling of get_settings to avoid raising errors on 404
    def get_settings(*args)
      SafeIndex.log_or_throw(:get_settings, @raise_on_failure) do
        begin
          @index.get_settings(*args)
        rescue Algolia::AlgoliaHttpError => e
          return {} if e.code == 404 # not fatal
          raise e
        end
      end
    end

    # expose move as well
    def self.move_index(old_name, new_name)
      SafeIndex.log_or_throw(:move_index, true) do
        AlgoliaSearch.client.move_index(old_name, new_name)
      end
    end

    private
    def self.log_or_throw(method, raise_on_failure, &block)
      begin
        yield
      rescue Algolia::AlgoliaError => e
        raise e if raise_on_failure
        # log the error
        (Rails.logger || Logger.new(STDOUT)).error("[algoliasearch-rails] #{e.message}")
        # return something
        case method.to_s
        when 'search'
          # some attributes are required
          { 'hits' => [], 'hitsPerPage' => 0, 'page' => 0, 'facets' => {}, 'error' => e }
        else
          # empty answer
          { 'error' => e }
        end
      end
    end
  end

  # these are the class methods added when AlgoliaSearch is included
  module ClassMethods

    def self.extended(base)
      class <<base
        alias_method :without_auto_index, :algolia_without_auto_index unless method_defined? :without_auto_index
        alias_method :reindex!, :algolia_reindex! unless method_defined? :reindex!
        alias_method :reindex, :algolia_reindex unless method_defined? :reindex
        alias_method :index_objects, :algolia_index_objects unless method_defined? :index_objects
        alias_method :index!, :algolia_index! unless method_defined? :index!
        alias_method :remove_from_index!, :algolia_remove_from_index! unless method_defined? :remove_from_index!
        alias_method :clear_index!, :algolia_clear_index! unless method_defined? :clear_index!
        alias_method :search, :algolia_search unless method_defined? :search
        alias_method :raw_search, :algolia_raw_search unless method_defined? :raw_search
        alias_method :search_facet, :algolia_search_facet unless method_defined? :search_facet
        alias_method :search_for_facet_values, :algolia_search_for_facet_values unless method_defined? :search_for_facet_values
        alias_method :index, :algolia_index unless method_defined? :index
        alias_method :index_name, :algolia_index_name unless method_defined? :index_name
        alias_method :must_reindex?, :algolia_must_reindex? unless method_defined? :must_reindex?
      end

      base.cattr_accessor :algoliasearch_options, :algoliasearch_settings
    end

    def algoliasearch(options = {}, &block)
      self.algoliasearch_settings = IndexSettings.new(options, &block)
      self.algoliasearch_options = { :type => algolia_full_const_get(model_name.to_s), :per_page => algoliasearch_settings.get_setting(:hitsPerPage) || 10, :page => 1 }.merge(options)

      attr_accessor :highlight_result, :snippet_result

      if options[:synchronous] == true
        if defined?(::Sequel) && defined?(::Sequel::Model) && self < Sequel::Model
          class_eval do
            copy_after_validation = instance_method(:after_validation)
            define_method(:after_validation) do |*args|
              super(*args)
              copy_after_validation.bind(self).call
              algolia_mark_synchronous
            end
          end
        else
          after_validation :algolia_mark_synchronous if respond_to?(:after_validation)
        end
      end
      if options[:enqueue]
        raise ArgumentError.new("Cannot use a enqueue if the `synchronous` option if set") if options[:synchronous]
        proc = if options[:enqueue] == true
          Proc.new do |record, remove|
            AlgoliaJob.perform_later(record, remove ? 'algolia_remove_from_index!' : 'algolia_index!')
          end
        elsif options[:enqueue].respond_to?(:call)
          options[:enqueue]
        elsif options[:enqueue].is_a?(Symbol)
          Proc.new { |record, remove| self.send(options[:enqueue], record, remove) }
        else
          raise ArgumentError.new("Invalid `enqueue` option: #{options[:enqueue]}")
        end
        algoliasearch_options[:enqueue] = Proc.new do |record, remove|
          proc.call(record, remove) unless algolia_without_auto_index_scope
        end
      end
      unless options[:auto_index] == false
        if defined?(::Sequel) && defined?(::Sequel::Model) && self < Sequel::Model
          class_eval do
            copy_after_validation = instance_method(:after_validation)
            copy_before_save = instance_method(:before_save)

            define_method(:after_validation) do |*args|
              super(*args)
              copy_after_validation.bind(self).call
              algolia_mark_must_reindex
            end

            define_method(:before_save) do |*args|
              copy_before_save.bind(self).call
              algolia_mark_for_auto_indexing
              super(*args)
            end

            sequel_version = Gem::Version.new(Sequel.version)
            if sequel_version >= Gem::Version.new('4.0.0') && sequel_version < Gem::Version.new('5.0.0')
              copy_after_commit = instance_method(:after_commit)
              define_method(:after_commit) do |*args|
                super(*args)
                copy_after_commit.bind(self).call
                algolia_perform_index_tasks
              end
            else
              copy_after_save = instance_method(:after_save)
              define_method(:after_save) do |*args|
                super(*args)
                copy_after_save.bind(self).call
                self.db.after_commit do
                  algolia_perform_index_tasks
                end
              end
            end
          end
        else
          after_validation :algolia_mark_must_reindex if respond_to?(:after_validation)
          before_save :algolia_mark_for_auto_indexing if respond_to?(:before_save)
          if respond_to?(:after_commit)
            after_commit :algolia_perform_index_tasks
          elsif respond_to?(:after_save)
            after_save :algolia_perform_index_tasks
          end
        end
      end
      unless options[:auto_remove] == false
        if defined?(::Sequel) && defined?(::Sequel::Model) && self < Sequel::Model
          class_eval do
            copy_after_destroy = instance_method(:after_destroy)

            define_method(:after_destroy) do |*args|
              copy_after_destroy.bind(self).call
              algolia_enqueue_remove_from_index!(algolia_synchronous?)
              super(*args)
            end
          end
        else
          after_destroy { |searchable| searchable.algolia_enqueue_remove_from_index!(algolia_synchronous?) } if respond_to?(:after_destroy)
        end
      end
    end

    def algolia_without_auto_index(&block)
      self.algolia_without_auto_index_scope = true
      begin
        yield
      ensure
        self.algolia_without_auto_index_scope = false
      end
    end

    def algolia_without_auto_index_scope=(value)
      Thread.current["algolia_without_auto_index_scope_for_#{self.model_name}"] = value
    end

    def algolia_without_auto_index_scope
      Thread.current["algolia_without_auto_index_scope_for_#{self.model_name}"]
    end

    def algolia_reindex!(batch_size = AlgoliaSearch::IndexSettings::DEFAULT_BATCH_SIZE, synchronous = false)
      return if algolia_without_auto_index_scope
      algolia_configurations.each do |options, settings|
        next if algolia_indexing_disabled?(options)
        index = algolia_ensure_init(options, settings)
        next if options[:replica]
        last_task = nil

        algolia_find_in_batches(batch_size) do |group|
          if algolia_conditional_index?(options)
            # delete non-indexable objects
            ids = group.select { |o| !algolia_indexable?(o, options) }.map { |o| algolia_object_id_of(o, options) }
            index.delete_objects(ids.select { |id| !id.blank? })
            # select only indexable objects
            group = group.select { |o| algolia_indexable?(o, options) }
          end
          objects = group.map do |o|
            attributes = settings.get_attributes(o)
            unless attributes.class == Hash
              attributes = attributes.to_hash
            end
            attributes.merge 'objectID' => algolia_object_id_of(o, options)
          end
          last_task = index.save_objects(objects)
        end
        index.wait_task(last_task.raw_response["taskID"]) if last_task and (synchronous || options[:synchronous])
      end
      nil
    end

    # reindex whole database using a extra temporary index + move operation
    def algolia_reindex(batch_size = AlgoliaSearch::IndexSettings::DEFAULT_BATCH_SIZE, synchronous = false)
      return if algolia_without_auto_index_scope
      algolia_configurations.each do |options, settings|
        next if algolia_indexing_disabled?(options)
        next if options[:replica]

        # fetch the master settings
        master_index = algolia_ensure_init(options, settings)
        master_settings = master_index.get_settings rescue {} # if master doesn't exist yet
        master_exists = master_settings != {}
        master_settings.merge!(JSON.parse(settings.to_settings.to_json)) # convert symbols to strings

        # remove the replicas of the temporary index
        master_settings.delete :replicas
        master_settings.delete 'replicas'

        # init temporary index
        src_index_name = algolia_index_name(options)
        tmp_index_name = "#{src_index_name}.tmp"
        tmp_options = options.merge({ :index_name => tmp_index_name })
        tmp_options.delete(:per_environment) # already included in the temporary index_name
        tmp_settings = settings.dup

        if options[:check_settings] == false && master_exists
          AlgoliaSearch.client.copy_index!(src_index_name, tmp_index_name, { scope: %w[settings synonyms rules] })
          tmp_index = SafeIndex.new(tmp_index_name, !!options[:raise_on_failure])
        else
          tmp_index = algolia_ensure_init(tmp_options, tmp_settings, master_settings)
        end

        algolia_find_in_batches(batch_size) do |group|
          if algolia_conditional_index?(options)
            # select only indexable objects
            group = group.select { |o| algolia_indexable?(o, tmp_options) }
          end
          objects = group.map { |o| tmp_settings.get_attributes(o).merge 'objectID' => algolia_object_id_of(o, tmp_options) }
          tmp_index.save_objects(objects)
        end

        move_task = SafeIndex.move_index(tmp_index.name, src_index_name)
        master_index.wait_task(move_task.raw_response["taskID"]) if synchronous || options[:synchronous]
      end
      nil
    end

    def algolia_set_settings(synchronous = false)
      algolia_configurations.each do |options, settings|
        if options[:primary_settings] && options[:inherit]
          primary = options[:primary_settings].to_settings
          primary.delete :replicas
          primary.delete 'replicas'
          final_settings = primary.merge(settings.to_settings)
        else
          final_settings = settings.to_settings
        end

        index = SafeIndex.new(algolia_index_name(options), true)
        task = index.set_settings(final_settings)
        index.wait_task(task.raw_response["taskID"]) if synchronous
      end
    end

    def algolia_index_objects(objects, synchronous = false)
      algolia_configurations.each do |options, settings|
        next if algolia_indexing_disabled?(options)
        index = algolia_ensure_init(options, settings)
        next if options[:replica]
        task = index.save_objects(objects.map { |o| settings.get_attributes(o).merge 'objectID' => algolia_object_id_of(o, options) })
        index.wait_task(task.raw_response["taskID"]) if synchronous || options[:synchronous]
      end
    end

    def algolia_index!(object, synchronous = false)
      return if algolia_without_auto_index_scope
      algolia_configurations.each do |options, settings|
        next if algolia_indexing_disabled?(options)
        object_id = algolia_object_id_of(object, options)
        index = algolia_ensure_init(options, settings)
        next if options[:replica]
        if algolia_indexable?(object, options)
          raise ArgumentError.new("Cannot index a record with a blank objectID") if object_id.blank?
          if synchronous || options[:synchronous]
            index.save_object!(settings.get_attributes(object).merge 'objectID' => algolia_object_id_of(object, options))
          else
            index.save_object(settings.get_attributes(object).merge 'objectID' => algolia_object_id_of(object, options))
          end
        elsif algolia_conditional_index?(options) && !object_id.blank?
          # remove non-indexable objects
          if synchronous || options[:synchronous]
            index.delete_object!(object_id)
          else
            index.delete_object(object_id)
          end
        end
      end
      nil
    end

    def algolia_remove_from_index!(object, synchronous = false)
      return if algolia_without_auto_index_scope
      object_id = algolia_object_id_of(object)
      raise ArgumentError.new("Cannot index a record with a blank objectID") if object_id.blank?
      algolia_configurations.each do |options, settings|
        next if algolia_indexing_disabled?(options)
        index = algolia_ensure_init(options, settings)
        next if options[:replica]
        if synchronous || options[:synchronous]
          index.delete_object!(object_id)
        else
          index.delete_object(object_id)
        end
      end
      nil
    end

    def algolia_clear_index!(synchronous = false)
      algolia_configurations.each do |options, settings|
        next if algolia_indexing_disabled?(options)
        index = algolia_ensure_init(options, settings)
        next if options[:replica]
        synchronous || options[:synchronous] ? index.clear_objects! : index.clear_objects
        @algolia_indexes[settings] = nil
      end
      nil
    end

    def algolia_raw_search(q, params = {})
      index_name = params.delete(:index) ||
                   params.delete('index') ||
                   params.delete(:replica) ||
                   params.delete('replica')
      index = algolia_index(index_name)
      index.search(q, Hash[params.map { |k,v| [k.to_s, v.to_s] }])
    end

    module AdditionalMethods
      def self.extended(base)
        class <<base
          alias_method :raw_answer, :algolia_raw_answer unless method_defined? :raw_answer
          alias_method :facets, :algolia_facets unless method_defined? :facets
        end
      end

      def algolia_raw_answer
        @algolia_json
      end

      def algolia_facets
        @algolia_json['facets']
      end

      private
      def algolia_init_raw_answer(json)
        @algolia_json = json
      end
    end

    def algolia_search(q, params = {})
      if AlgoliaSearch.configuration[:pagination_backend]
        # kaminari, will_paginate, and pagy start pagination at 1, Algolia starts at 0
        params[:page] = (params.delete('page') || params.delete(:page)).to_i
        params[:page] -= 1 if params[:page].to_i > 0
      end
      json = algolia_raw_search(q, params)
      hit_ids = json['hits'].map { |hit| hit['objectID'] }
      if defined?(::Mongoid::Document) && self.include?(::Mongoid::Document)
        condition_key = algolia_object_id_method.in
      else
        condition_key = algolia_object_id_method
      end
      results_by_id = algoliasearch_options[:type].where(condition_key => hit_ids).index_by do |hit|
        algolia_object_id_of(hit)
      end
      results = json['hits'].map do |hit|
        o = results_by_id[hit['objectID'].to_s]
        if o
          o.highlight_result = hit['_highlightResult']
          o.snippet_result = hit['_snippetResult']
          o
        end
      end.compact
      # Algolia has a default limit of 1000 retrievable hits
      total_hits = json['nbHits'].to_i < json['nbPages'].to_i * json['hitsPerPage'].to_i ?
        json['nbHits'].to_i: json['nbPages'].to_i * json['hitsPerPage'].to_i
      res = AlgoliaSearch::Pagination.create(results, total_hits, algoliasearch_options.merge({ :page => json['page'].to_i + 1, :per_page => json['hitsPerPage'] }))
      res.extend(AdditionalMethods)
      res.send(:algolia_init_raw_answer, json)
      res
    end

    def algolia_search_for_facet_values(facet, text, params = {})
      index_name = params.delete(:index) ||
                   params.delete('index') ||
                   params.delete(:replica) ||
                   params.delete('replicas')
      index = algolia_index(index_name)
      query = Hash[params.map { |k, v| [k.to_s, v.to_s] }]
      index.search_for_facet_values(facet, text, query)['facetHits']
    end

    # deprecated (renaming)
    alias :algolia_search_facet :algolia_search_for_facet_values

    def algolia_index(name = nil)
      if name
        algolia_configurations.each do |o, s|
          return algolia_ensure_init(o, s) if o[:index_name].to_s == name.to_s
        end
        raise ArgumentError.new("Invalid index/replica name: #{name}")
      end
      algolia_ensure_init
    end

    def algolia_index_name(options = nil)
      options ||= algoliasearch_options
      name = options[:index_name] || model_name.to_s.gsub('::', '_')
      name = "#{name}_#{Rails.env.to_s}" if options[:per_environment]
      name
    end

    def algolia_must_reindex?(object)
      # use +algolia_dirty?+ method if implemented
      return object.send(:algolia_dirty?) if (object.respond_to?(:algolia_dirty?))
      # Loop over each index to see if a attribute used in records has changed
      algolia_configurations.each do |options, settings|
        next if algolia_indexing_disabled?(options)
        next if options[:replica]
        return true if algolia_object_id_changed?(object, options)
        settings.get_attribute_names(object).each do |k|
          return true if algolia_attribute_changed?(object, k, true)
        end
        [options[:if], options[:unless]].each do |condition|
          case condition
          when nil
          when String, Symbol
            return true if algolia_attribute_changed?(object, condition, true)
          else
            # if the :if, :unless condition is a anything else,
            # we have no idea whether we should reindex or not
            # let's always reindex then
            return true
          end
        end
      end
      # By default, we don't reindex
      return false
    end

    protected

    def algolia_ensure_init(options = nil, settings = nil, index_settings = nil)
      raise ArgumentError.new('No `algoliasearch` block found in your model.') if algoliasearch_settings.nil?

      @algolia_indexes ||= {}

      options ||= algoliasearch_options
      settings ||= algoliasearch_settings

      return @algolia_indexes[settings] if @algolia_indexes[settings]

      @algolia_indexes[settings] = SafeIndex.new(algolia_index_name(options), algoliasearch_options[:raise_on_failure])

      index_settings ||= settings.to_settings
      index_settings = options[:primary_settings].to_settings.merge(index_settings) if options[:inherit]
      replicas = index_settings.delete(:replicas) ||
                 index_settings.delete('replicas')
      index_settings[:replicas] = replicas unless replicas.nil? || options[:inherit]

      options[:check_settings] = true if options[:check_settings].nil?

      current_settings = if options[:check_settings] && !algolia_indexing_disabled?(options)
                           @algolia_indexes[settings].get_settings(:getVersion => 1) rescue nil # if the index doesn't exist
                         end

      if !algolia_indexing_disabled?(options) && options[:check_settings] && algoliasearch_settings_changed?(current_settings, index_settings)
        set_settings_method = options[:synchronous] ? :set_settings! : :set_settings
        @algolia_indexes[settings].send(set_settings_method, index_settings)
      end

      @algolia_indexes[settings]
    end

    private

    def algolia_configurations
      raise ArgumentError.new('No `algoliasearch` block found in your model.') if algoliasearch_settings.nil?
      if @configurations.nil?
        @configurations = {}
        @configurations[algoliasearch_options] = algoliasearch_settings
        algoliasearch_settings.additional_indexes.each do |k,v|
          @configurations[k] = v

          if v.additional_indexes.any?
            v.additional_indexes.each do |options, index|
              @configurations[options] = index
            end
          end
        end
      end
      @configurations
    end

    def algolia_object_id_method(options = nil)
      options ||= algoliasearch_options
      options[:id] || options[:object_id] || :id
    end

    def algolia_object_id_of(o, options = nil)
      o.send(algolia_object_id_method(options)).to_s
    end

    def algolia_object_id_changed?(o, options = nil)
      changed = algolia_attribute_changed?(o, algolia_object_id_method(options), false)
      changed.nil? ? false : changed
    end

    def algoliasearch_settings_changed?(prev, current)
      return true if prev.nil?
      current.each do |k, v|
        prev_v = prev[k.to_s]
        if v.is_a?(Array) and prev_v.is_a?(Array)
          # compare array of strings, avoiding symbols VS strings comparison
          return true if v.map { |x| x.to_s } != prev_v.map { |x| x.to_s }
        elsif v.blank? # blank? check is needed to compare [] and null
          return true unless prev_v.blank?
        else
          return true if prev_v != v
        end
      end
      false
    end

    def algolia_full_const_get(name)
      list = name.split('::')
      list.shift if list.first.blank?
      obj = Object.const_defined?(:RUBY_VERSION) && RUBY_VERSION.to_f < 1.9 ? Object : self
      list.each do |x|
        # This is required because const_get tries to look for constants in the
        # ancestor chain, but we only want constants that are HERE
        obj = obj.const_defined?(x) ? obj.const_get(x) : obj.const_missing(x)
      end
      obj
    end

    def algolia_conditional_index?(options = nil)
      options ||= algoliasearch_options
      options[:if].present? || options[:unless].present?
    end

    def algolia_indexable?(object, options = nil)
      options ||= algoliasearch_options
      if_passes = options[:if].blank? || algolia_constraint_passes?(object, options[:if])
      unless_passes = options[:unless].blank? || !algolia_constraint_passes?(object, options[:unless])
      if_passes && unless_passes
    end

    def algolia_constraint_passes?(object, constraint)
      case constraint
      when Symbol
        object.send(constraint)
      when String
        object.send(constraint.to_sym)
      when Enumerable
        # All constraints must pass
        constraint.all? { |inner_constraint| algolia_constraint_passes?(object, inner_constraint) }
      else
        if constraint.respond_to?(:call) # Proc
          constraint.call(object)
        else
          raise ArgumentError, "Unknown constraint type: #{constraint} (#{constraint.class})"
        end
      end
    end

    def algolia_indexing_disabled?(options = nil)
      options ||= algoliasearch_options
      constraint = options[:disable_indexing] || options['disable_indexing']
      case constraint
      when nil
        return false
      when true, false
        return constraint
      when String, Symbol
        return send(constraint)
      else
        return constraint.call if constraint.respond_to?(:call) # Proc
      end
      raise ArgumentError, "Unknown constraint type: #{constraint} (#{constraint.class})"
    end

    def algolia_find_in_batches(batch_size, &block)
      if (defined?(::ActiveRecord) && ancestors.include?(::ActiveRecord::Base)) || respond_to?(:find_in_batches)
        find_in_batches(:batch_size => batch_size, &block)
      elsif defined?(::Sequel) && defined?(::Sequel::Model) && self < Sequel::Model
        dataset.extension(:pagination).each_page(batch_size, &block)
      else
        # don't worry, mongoid has its own underlying cursor/streaming mechanism
        items = []
        all.each do |item|
          items << item
          if items.length % batch_size == 0
            yield items
            items = []
          end
        end
        yield items unless items.empty?
      end
    end

    def algolia_attribute_changed?(object, attr_name, default)
      # if one of two method is implemented, we return its result
      # true/false means whether it has changed or not
      # +#{attr_name}_changed?+ always defined for automatic attributes but deprecated after Rails 5.2
      # +will_save_change_to_#{attr_name}?+ should be use instead for Rails 5.2+, also defined for automatic attributes.
      # If none of the method are defined, it's a dynamic attribute

      method_name = "#{attr_name}_changed?"
      if object.respond_to?(method_name)
        # If +#{attr_name}_changed?+ respond we want to see if the method is user defined or if it's automatically
        # defined by Rails.
        # If it's user-defined, we call it.
        # If it's automatic we check ActiveRecord version to see if this method is deprecated
        # and try to call +will_save_change_to_#{attr_name}?+ instead.
        # See: https://github.com/algolia/algoliasearch-rails/pull/338
        # This feature is not compatible with Ruby 1.8
        # In this case, we always call #{attr_name}_changed?
        if Object.const_defined?(:RUBY_VERSION) && RUBY_VERSION.to_f < 1.9
          return object.send(method_name)
        end
        unless automatic_changed_method?(object, method_name) && automatic_changed_method_deprecated?
          return object.send(method_name)
        end
      end

      if object.respond_to?("will_save_change_to_#{attr_name}?")
        return object.send("will_save_change_to_#{attr_name}?")
      end

      # We don't know if the attribute has changed, so return the default passed
      default
    end

    def automatic_changed_method?(object, method_name)
      raise ArgumentError.new("Method #{method_name} doesn't exist on #{object.class.name}") unless object.respond_to?(method_name)
      file = object.method(method_name).source_location[0]
      file.end_with?("active_model/attribute_methods.rb")
    end

    def automatic_changed_method_deprecated?
      (defined?(::ActiveRecord) && ActiveRecord::VERSION::MAJOR >= 5 && ActiveRecord::VERSION::MINOR >= 1) ||
          (defined?(::ActiveRecord) && ActiveRecord::VERSION::MAJOR > 5)
    end
  end

  # these are the instance methods included
  module InstanceMethods

    def self.included(base)
      base.instance_eval do
        alias_method :index!, :algolia_index! unless method_defined? :index!
        alias_method :remove_from_index!, :algolia_remove_from_index! unless method_defined? :remove_from_index!
      end
    end

    def algolia_index!(synchronous = false)
      self.class.algolia_index!(self, synchronous || algolia_synchronous?)
    end

    def algolia_remove_from_index!(synchronous = false)
      self.class.algolia_remove_from_index!(self, synchronous || algolia_synchronous?)
    end

    def algolia_enqueue_remove_from_index!(synchronous)
      if algoliasearch_options[:enqueue]
        algoliasearch_options[:enqueue].call(self, true) unless self.class.send(:algolia_indexing_disabled?, algoliasearch_options)
      else
        algolia_remove_from_index!(synchronous || algolia_synchronous?)
      end
    end

    def algolia_enqueue_index!(synchronous)
      if algoliasearch_options[:enqueue]
        algoliasearch_options[:enqueue].call(self, false) unless self.class.send(:algolia_indexing_disabled?, algoliasearch_options)
      else
        algolia_index!(synchronous)
      end
    end

    private

    def algolia_synchronous?
      @algolia_synchronous == true
    end

    def algolia_mark_synchronous
      @algolia_synchronous = true
    end

    def algolia_mark_for_auto_indexing
      @algolia_auto_indexing = true
    end

    def algolia_mark_must_reindex
      # algolia_must_reindex flag is reset after every commit as part. If we must reindex at any point in
      # a stransaction, keep flag set until it is explicitly unset
      @algolia_must_reindex ||=
       if defined?(::Sequel) && defined?(::Sequel::Model) && is_a?(Sequel::Model)
         new? || self.class.algolia_must_reindex?(self)
       else
         new_record? || self.class.algolia_must_reindex?(self)
       end
      true
    end

    def algolia_perform_index_tasks
      return if !@algolia_auto_indexing || @algolia_must_reindex == false
      algolia_enqueue_index!(algolia_synchronous?)
      remove_instance_variable(:@algolia_auto_indexing) if instance_variable_defined?(:@algolia_auto_indexing)
      remove_instance_variable(:@algolia_synchronous) if instance_variable_defined?(:@algolia_synchronous)
      remove_instance_variable(:@algolia_must_reindex) if instance_variable_defined?(:@algolia_must_reindex)
    end
  end
end
