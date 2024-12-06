module CloudinaryHelper
  include ActionView::Helpers::CaptureHelper
  DEFAULT_POSTER_OPTIONS = { :format => 'jpg', :resource_type => 'video' }
  DEFAULT_SOURCE_TYPES   = %w(webm mp4 ogv)
  DEFAULT_VIDEO_OPTIONS  = { :resource_type => 'video' }
  DEFAULT_SOURCES        = [
    {
      :type            => "mp4",
      :codecs          => "hev1",
      :transformations => { :video_codec => "h265" }
    },
    {
      :type            => "webm",
      :codecs          => "vp9",
      :transformations => { :video_codec => "vp9" }
    },
    {
      :type            => "mp4",
      :transformations => { :video_codec => "auto" }
    },
    {
      :type            => "webm",
      :transformations => { :video_codec => "auto" }
    }
  ]

  # Creates an HTML video tag for the provided +source+
  #
  # ==== Options
  # * <tt>:source_types</tt> - Specify which source type the tag should include. defaults to webm, mp4 and ogv.
  # * <tt>:source_transformation</tt> - specific transformations to use for a specific source type.
  # * <tt>:sources</tt> - list of sources (overrides :source_types when present)
  # * <tt>:poster</tt> - override default thumbnail:
  #   * url: provide an ad hoc url
  #   * options: with specific poster transformations and/or Cloudinary +:public_id+
  #
  # ==== Examples
  #   cl_video_tag("mymovie.mp4")
  #   cl_video_tag("mymovie.mp4", :source_types => :webm)
  #   cl_video_tag("mymovie.ogv", :poster => "myspecialplaceholder.jpg")
  #   cl_video_tag("mymovie.webm", :source_types => [:webm, :mp4], :poster => {:effect => 'sepia'}) do
  #     content_tag( :span, "Cannot present video!")
  #   end
  #   cl_video_tag("mymovie", :sources => [
  #     {
  #       :type => "mp4",
  #       :codecs => "hev1",
  #       :transformations => { :video_codec => "h265" }
  #     },
  #     {
  #       :type => "webm",
  #       :transformations => { :video_codec => "auto" }
  #     }
  #   ])
  def cl_video_tag(source, options = {}, &block)
    source = strip_known_ext(source) unless Cloudinary::Utils.config_option_fetch(options, :use_fetch_format)
    video_attributes = [:autoplay,:controls,:loop,:muted,:poster, :preload]
    options = Cloudinary::Utils.deep_symbolize_keys(DEFAULT_VIDEO_OPTIONS.merge(options))

    options[:source_types] ||= DEFAULT_SOURCE_TYPES
    video_attributes.keep_if{ |key, _| options.has_key?(key)} # required prior to Rails 4.x
    video_options = options.extract!(*video_attributes)
    if video_options.has_key? :poster
      poster = video_options.delete(:poster)
      case poster
      when String
        video_options[:poster] = poster
      when Hash
        if poster.has_key? :public_id
          poster[:resource_type] = "image"
          poster_name            = poster[:public_id]
          video_options[:poster] = cl_image_path(poster_name, poster)
        else
          video_options[:poster] = cl_video_thumbnail_path(source, poster)
        end
      else
        # no poster
      end
    else
      video_options[:poster] = cl_video_thumbnail_path(source, options)
    end

    fallback = (capture(&block) if block_given?) || options.delete(:fallback_content)

    if options[:sources]
      video_tag_from_sources(source, options, video_options, fallback)
    else
      video_tag_from_source_types(source, options, video_options, fallback)
    end
  end

  # Returns a url for the given source with +options+
  def cl_video_path(source, options={})
    cl_image_path(source, DEFAULT_VIDEO_OPTIONS.merge(options))
  end

  # Returns an HTML <tt>img</tt> tag with the thumbnail for the given video +source+ and +options+
  def cl_video_thumbnail_tag(source, options={})
    cl_image_tag(source, DEFAULT_POSTER_OPTIONS.merge(options))
  end

  # Returns a url for the thumbnail for the given video +source+ and +options+
  def cl_video_thumbnail_path(source, options={})
    cl_image_path(source, DEFAULT_POSTER_OPTIONS.merge(options))
  end

  protected

  def strip_known_ext(name)
    name.sub(/\.(#{DEFAULT_SOURCE_TYPES.join("|")})$/, '')
  end

  private

  def video_tag_from_source_types(source_name, options, video_options, fallback)
    source_transformation = options.delete(:source_transformation) || {}
    source_types = Array(options.delete(:source_types))

    if source_types.size > 1
      sources = source_types.map do |type|
        {
          :type => type,
          :transformations => source_transformation[type.to_sym] || {}
        }
      end

      generate_tag_from_sources(:source_name => source_name,
                                :sources => sources,
                                :options => options,
                                :video_options => video_options,
                                :fallback => fallback)
    else
      transformation      = source_transformation[source_types.first.to_sym] || {}
      video_options[:src] = cl_video_path("#{source_name}.#{source_types.first.to_sym}", transformation.merge(options))
      cloudinary_tag(source_name, options) do |_source, tag_options|
        content_tag('video', fallback, tag_options.merge(video_options))
      end
    end
  end

  def video_tag_from_sources(source_name, options, video_options, fallback)
    sources = options.delete(:sources)

    generate_tag_from_sources(:source_name => source_name,
                              :sources => sources,
                              :options => options,
                              :video_options => video_options,
                              :fallback => fallback)
  end

  def generate_tag_from_sources(params)
    source_name, sources, options, video_options, fallback = params.values_at(:source_name, :sources, :options, :video_options, :fallback)

    cloudinary_tag(source_name, options) do |_source, tag_options|
      content_tag('video', tag_options.merge(video_options)) do
        source_tags = sources.map do |source|
          type = source[:type]
          options[:format] = type
          transformation = source[:transformations] || {}
          cloudinary_tag(source_name, options.merge(transformation)) do |url, _tag_options|
            mime_type = "video/#{(type == 'ogv' ? 'ogg' : type)}"
            if source[:codecs]
              codecs = source[:codecs].is_a?(Array) ? source[:codecs].join(", ") : source[:codecs]
              mime_type = "#{mime_type}; codecs=#{codecs}"
            end
            tag("source", :src => url, :type => mime_type)
          end
        end
        source_tags.push(fallback.html_safe) unless fallback.blank?
        safe_join(source_tags)
      end
    end
  end
end





