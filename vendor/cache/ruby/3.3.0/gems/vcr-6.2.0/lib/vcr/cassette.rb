require 'vcr/cassette/http_interaction_list'
require 'vcr/cassette/erb_renderer'
require 'vcr/cassette/serializers'

module VCR
  # The media VCR uses to store HTTP interactions for later re-use.
  class Cassette
    include Logger::Mixin

    # The supported record modes.
    #
    #   * :all -- Record every HTTP interactions; do not play any back.
    #   * :none -- Do not record any HTTP interactions; play them back.
    #   * :new_episodes -- Playback previously recorded HTTP interactions and record new ones.
    #   * :once -- Record the HTTP interactions if the cassette has not already been recorded;
    #              otherwise, playback the HTTP interactions.
    VALID_RECORD_MODES = [:all, :none, :new_episodes, :once]

    # @return [#to_s] The name of the cassette. Used to determine the cassette's file name.
    # @see #file
    attr_reader :name

    # @return [Symbol] The record mode. Determines whether the cassette records HTTP interactions,
    #  plays them back, or does both.
    attr_reader :record_mode

    # @return [Boolean] The cassette's record_on_error mode. When the code that uses the cassette
    #  raises an error (for example a test failure) and record_on_error is set to false, no
    #  cassette will be recorded. This is useful when you are TDD'ing an API integration: when
    #  an error is raised that often means your request is invalid, so you don't want the cassette
    #  to be recorded.
    attr_reader :record_on_error

    # @return [Array<Symbol, #call>] List of request matchers. Used to find a response from an
    #  existing HTTP interaction to play back.
    attr_reader :match_requests_on

    # @return [Boolean, Hash] The cassette's ERB option. The file will be treated as an
    #  ERB template if this has a truthy value. A hash, if provided, will be used as local
    #  variables for the ERB template.
    attr_reader :erb

    # @return [Integer, nil] How frequently (in seconds) the cassette should be re-recorded.
    attr_reader :re_record_interval

    # @return [Boolean, nil] Should outdated interactions be recorded back to file
    attr_reader :clean_outdated_http_interactions

    # @return [Boolean] Should unused requests be dropped from the cassette?
    attr_reader :drop_unused_requests

    # @return [Array<Symbol>] If set, {VCR::Configuration#before_record} and
    #  {VCR::Configuration#before_playback} hooks with a corresponding tag will apply.
    attr_reader :tags

    # @param (see VCR#insert_cassette)
    # @see VCR#insert_cassette
    def initialize(name, options = {})
      @name    = name
      @options = VCR.configuration.default_cassette_options.merge(options)
      @mutex   = Mutex.new

      assert_valid_options!
      extract_options
      raise_error_unless_valid_record_mode

      log "Initialized with options: #{@options.inspect}"
    end

    # Ejects the current cassette. The cassette will no longer be used.
    # In addition, any newly recorded HTTP interactions will be written to
    # disk.
    #
    # @note This is not intended to be called directly. Use `VCR.eject_cassette` instead.
    #
    # @param (see VCR#eject_casssette)
    # @see VCR#eject_cassette
    def eject(options = {})
      write_recorded_interactions_to_disk if should_write_recorded_interactions_to_disk?

      if should_assert_no_unused_interactions? && !options[:skip_no_unused_interactions_assertion]
        http_interactions.assert_no_unused_interactions!
      end
    end

    # @private
    def run_failed!
      @run_failed = true
    end

    # @private
    def run_failed?
      @run_failed = false unless defined?(@run_failed)
      @run_failed
    end

    def should_write_recorded_interactions_to_disk?
      !run_failed? || record_on_error
    end

    # @private
    def http_interactions
      # Without this mutex, under threaded access, an HTTPInteractionList will overwrite
      # the first.
      @mutex.synchronize do
        @http_interactions ||= HTTPInteractionList.new \
          should_stub_requests? ? previously_recorded_interactions : [],
          match_requests_on,
          @allow_playback_repeats,
          @parent_list,
          log_prefix
      end
    end

    # @private
    def record_http_interaction(interaction)
      VCR::CassetteMutex.synchronize do
        log "Recorded HTTP interaction #{request_summary(interaction.request)} => #{response_summary(interaction.response)}"
        new_recorded_interactions << interaction
      end
    end

    # @private
    def new_recorded_interactions
      @new_recorded_interactions ||= []
    end

    # @return [String] The file for this cassette.
    # @raise [NotImplementedError] if the configured cassette persister
    #  does not support resolving file paths.
    # @note VCR will take care of sanitizing the cassette name to make it a valid file name.
    def file
      unless @persister.respond_to?(:absolute_path_to_file)
        raise NotImplementedError, "The configured cassette persister does not support resolving file paths"
      end
      @persister.absolute_path_to_file(storage_key)
    end

    # @return [Boolean] Whether or not the cassette is recording.
    def recording?
      case record_mode
        when :none; false
        when :once; raw_cassette_bytes.to_s.empty?
        else true
      end
    end

    # @return [Hash] The hash that will be serialized when the cassette is written to disk.
    def serializable_hash
      {
        "http_interactions" => interactions_to_record.map(&:to_hash),
        "recorded_with"     => "VCR #{VCR.version}"
      }
    end

    # @return [Time, nil] The `recorded_at` time of the first HTTP interaction
    #                     or nil if the cassette has no prior HTTP interactions.
    #
    # @example
    #
    #   VCR.use_cassette("some cassette") do |cassette|
    #     Timecop.freeze(cassette.originally_recorded_at || Time.now) do
    #       # ...
    #     end
    #   end
    def originally_recorded_at
      @originally_recorded_at ||= previously_recorded_interactions.map(&:recorded_at).min
    end

    # @return [Boolean] false unless wrapped with LinkedCassette
    def linked?
      false
    end

  private

    def assert_valid_options!
      invalid_options = @options.keys - [
        :record, :record_on_error, :erb, :match_requests_on, :re_record_interval, :tag, :tags,
        :update_content_length_header, :allow_playback_repeats, :allow_unused_http_interactions,
        :exclusive, :serialize_with, :preserve_exact_body_bytes, :decode_compressed_response,
        :recompress_response, :persist_with, :persister_options, :clean_outdated_http_interactions,
        :drop_unused_requests
      ]

      if invalid_options.size > 0
        raise ArgumentError.new("You passed the following invalid options to VCR::Cassette.new: #{invalid_options.inspect}.")
      end
    end

    def extract_options
      [:record_on_error, :erb, :match_requests_on, :re_record_interval, :clean_outdated_http_interactions,
       :allow_playback_repeats, :allow_unused_http_interactions, :exclusive, :drop_unused_requests].each do |name|
        instance_variable_set("@#{name}", @options[name])
      end

      assign_tags

      @serializer  = VCR.cassette_serializers[@options[:serialize_with]]
      @persister   = VCR.cassette_persisters[@options[:persist_with]]
      @record_mode = should_re_record?(@options[:record]) ? :all : @options[:record]
      @parent_list = @exclusive ? HTTPInteractionList::NullList : VCR.http_interactions
    end

    def assign_tags
      @tags = Array(@options.fetch(:tags) { @options[:tag] })

      [:update_content_length_header, :preserve_exact_body_bytes, :decode_compressed_response, :recompress_response].each do |tag|
        @tags << tag if @options[tag]
      end
    end

    def previously_recorded_interactions
      @previously_recorded_interactions ||= if !raw_cassette_bytes.to_s.empty?
        deserialized_hash['http_interactions'].map { |h| HTTPInteraction.from_hash(h) }.tap do |interactions|
          invoke_hook(:before_playback, interactions)

          interactions.reject! do |i|
            i.request.uri.is_a?(String) && VCR.request_ignorer.ignore?(i.request)
          end
        end
      else
        []
      end
    end

    def storage_key
      @storage_key ||= [name, @serializer.file_extension].join('.')
    end

    def raise_error_unless_valid_record_mode
      unless VALID_RECORD_MODES.include?(record_mode)
        raise ArgumentError.new("#{record_mode} is not a valid cassette record mode.  Valid modes are: #{VALID_RECORD_MODES.inspect}")
      end
    end

    def should_re_record?(record_mode)
      return false unless @re_record_interval
      return false unless originally_recorded_at
      return false if record_mode == :none

      now = Time.now

      (originally_recorded_at + @re_record_interval < now).tap do |value|
        info = "previously recorded at: '#{originally_recorded_at}'; now: '#{now}'; interval: #{@re_record_interval} seconds"

        if !value
          log "Not re-recording since the interval has not elapsed (#{info})."
        elsif InternetConnection.available?
          log "re-recording (#{info})."
        else
          log "Not re-recording because no internet connection is available (#{info})."
          return false
        end
      end
    end

    def should_stub_requests?
      record_mode != :all
    end

    def should_remove_matching_existing_interactions?
      record_mode == :all
    end

    def should_remove_unused_interactions?
      @drop_unused_requests
    end

    def should_assert_no_unused_interactions?
      !(@allow_unused_http_interactions || $!)
    end

    def raw_cassette_bytes
      @raw_cassette_bytes ||= VCR::Cassette::ERBRenderer.new(@persister[storage_key], erb, name).render
    end

    def merged_interactions
      old_interactions = previously_recorded_interactions

      if should_remove_matching_existing_interactions?
        new_interaction_list = HTTPInteractionList.new(new_recorded_interactions, match_requests_on)
        old_interactions = old_interactions.reject do |i|
          new_interaction_list.response_for(i.request)
        end
      end

        if should_remove_unused_interactions?
          new_recorded_interactions
        else
          up_to_date_interactions(old_interactions) + new_recorded_interactions
        end
    end

    def up_to_date_interactions(interactions)
      return interactions unless clean_outdated_http_interactions && re_record_interval
      interactions.take_while { |x| x[:recorded_at] > Time.now - re_record_interval }
    end

    def interactions_to_record
      # We deep-dup the interactions by roundtripping them to/from a hash.
      # This is necessary because `before_record` can mutate the interactions.
      merged_interactions.map { |i| HTTPInteraction.from_hash(i.to_hash) }.tap do |interactions|
        invoke_hook(:before_record, interactions)
      end
    end

    def write_recorded_interactions_to_disk
      return if new_recorded_interactions.none?
      hash = serializable_hash
      return if hash["http_interactions"].none?

      @persister[storage_key] = @serializer.serialize(hash)
    end

    def invoke_hook(type, interactions)
      interactions.delete_if do |i|
        i.hook_aware.tap do |hw|
          VCR.configuration.invoke_hook(type, hw, self)
        end.ignored?
      end
    end

    def deserialized_hash
      @deserialized_hash ||= @serializer.deserialize(raw_cassette_bytes).tap do |hash|
        unless hash.is_a?(Hash) && hash['http_interactions'].is_a?(Array)
          raise Errors::InvalidCassetteFormatError.new \
            "#{file} does not appear to be a valid VCR 2.0 cassette. " +
            "VCR 1.x cassettes are not valid with VCR 2.0. When upgrading from " +
            "VCR 1.x, it is recommended that you delete all your existing cassettes and " +
            "re-record them, or use the provided vcr:migrate_cassettes rake task to migrate " +
            "them. For more info, see the VCR upgrade guide."
        end
      end
    end

    def log_prefix
      @log_prefix ||= "[Cassette: '#{name}'] "
    end

    def request_summary(request)
      super(request, match_requests_on)
    end
  end
end
