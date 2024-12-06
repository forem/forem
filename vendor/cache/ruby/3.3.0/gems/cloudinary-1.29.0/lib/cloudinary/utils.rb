# Copyright Cloudinary

# frozen_string_literal: true
require 'digest/sha1'
require 'zlib'
require 'uri'
require 'aws_cf_signer'
require 'json'
require 'cgi'
require 'cloudinary/auth_token'
require 'cloudinary/responsive'

class Cloudinary::Utils
  # @deprecated Use Cloudinary::SHARED_CDN
  SHARED_CDN = Cloudinary::SHARED_CDN
  MODE_DOWNLOAD = "download"
  DEFAULT_RESPONSIVE_WIDTH_TRANSFORMATION = {:width => :auto, :crop => :limit}
  CONDITIONAL_OPERATORS = {
    "=" => 'eq',
    "!=" => 'ne',
    "<" => 'lt',
    ">" => 'gt',
    "<=" => 'lte',
    ">=" => 'gte',
    "&&" => 'and',
    "||" => 'or',
    "*" => 'mul',
    "/" => 'div',
    "+" => 'add',
    "-" => 'sub',
    "^" => 'pow'
  }

  PREDEFINED_VARS = {
    "aspect_ratio"         => "ar",
    "aspectRatio"          => "ar",
    "current_page"         => "cp",
    "currentPage"          => "cp",
    "face_count"           => "fc",
    "faceCount"            => "fc",
    "height"               => "h",
    "initial_aspect_ratio" => "iar",
    "initialAspectRatio"   => "iar",
    "trimmed_aspect_ratio" => "tar",
    "trimmedAspectRatio"   => "tar",
    "initial_height"       => "ih",
    "initialHeight"        => "ih",
    "initial_width"        => "iw",
    "initialWidth"         => "iw",
    "page_count"           => "pc",
    "pageCount"            => "pc",
    "page_x"               => "px",
    "pageX"                => "px",
    "page_y"               => "py",
    "pageY"                => "py",
    "tags"                 => "tags",
    "initial_duration"     => "idu",
    "initialDuration"      => "idu",
    "duration"             => "du",
    "width"                => "w",
    "illustration_score"   => "ils",
    "illustrationScore"    => "ils",
    "context"              => "ctx"
  }

  SIMPLE_TRANSFORMATION_PARAMS = {
    :ac => :audio_codec,
    :af => :audio_frequency,
    :br => :bit_rate,
    :cs => :color_space,
    :d  => :default_image,
    :dl => :delay,
    :dn => :density,
    :du => :duration,
    :eo => :end_offset,
    :f  => :fetch_format,
    :g  => :gravity,
    :ki => :keyframe_interval,
    :p  => :prefix,
    :pg => :page,
    :so => :start_offset,
    :sp => :streaming_profile,
    :vc => :video_codec,
    :vs => :video_sampling
  }.freeze

  URL_KEYS = %w[
      api_secret
      auth_token
      cdn_subdomain
      cloud_name
      cname
      format
      private_cdn
      resource_type
      secure
      secure_cdn_subdomain
      secure_distribution
      shorten
      sign_url
      ssl_detected
      type
      url_suffix
      use_root_path
      version
  ].map(&:to_sym)


  TRANSFORMATION_PARAMS = %w[
      angle
      aspect_ratio
      audio_codec
      audio_frequency
      background
      bit_rate
      border
      color
      color_space
      crop
      custom_function
      default_image
      delay
      density
      dpr
      duration
      effect
      end_offset
      fetch_format
      flags
      fps
      gravity
      height
      if
      keyframe_interval
      offset
      opacity
      overlay
      page
      prefix
      quality
      radius
      raw_transformation
      responsive_width
      size
      start_offset
      streaming_profile
      transformation
      underlay
      variables
      video_codec
      video_sampling
      width
      x
      y
      zoom
  ].map(&:to_sym)

  REMOTE_URL_REGEX = %r(^ftp:|^https?:|^s3:|^gs:|^data:([\w-]+\/[\w-]+(\+[\w-]+)?)?(;[\w-]+=[\w-]+)*;base64,([a-zA-Z0-9\/+\n=]+)$)

  LONG_URL_SIGNATURE_LENGTH = 32
  SHORT_URL_SIGNATURE_LENGTH = 8

  UPLOAD_PREFIX = 'https://api.cloudinary.com'

  ALGO_SHA1 = :sha1
  ALGO_SHA256 = :sha256

  ALGORITHM_SIGNATURE = {
    ALGO_SHA1 => Digest::SHA1,
    ALGO_SHA256 => Digest::SHA256,
  }

  def self.extract_config_params(options)
      options.select{|k,v| URL_KEYS.include?(k)}
  end

  def self.extract_transformation_params(options)
    options.select{|k,v| TRANSFORMATION_PARAMS.include?(k)}
  end

  def self.chain_transformation(options, *transformation)
    base_options = extract_config_params(options)
    transformation = transformation.reject(&:nil?)
    base_options[:transformation] = build_array(extract_transformation_params(options)).concat(transformation)
    base_options
  end


  # Warning: options are being destructively updated!
  def self.generate_transformation_string(options={}, allow_implicit_crop_mode = false)
    # allow_implicit_crop_mode was added to support height and width parameters without specifying a crop mode.
    # This only apply to this (cloudinary_gem) SDK

    if options.is_a?(Array)
      return options.map{|base_transformation| generate_transformation_string(base_transformation.clone, allow_implicit_crop_mode)}.reject(&:blank?).join("/")
    end

    symbolize_keys!(options)

    responsive_width = config_option_consume(options, :responsive_width)
    size = options.delete(:size)
    options[:width], options[:height] = size.split("x") if size
    width = options[:width]
    width = width.to_s if width.is_a?(Symbol)
    height = options[:height]
    has_layer = options[:overlay].present? || options[:underlay].present?

    crop = options.delete(:crop)
    angle = build_array(options.delete(:angle)).join(".")

    no_html_sizes = has_layer || angle.present? || crop.to_s == "fit" || crop.to_s == "limit" || crop.to_s == "lfill"
    options.delete(:width) if width && (width.to_f < 1 || no_html_sizes || width.to_s.start_with?("auto") || responsive_width)
    options.delete(:height) if height && (height.to_f < 1 || no_html_sizes || responsive_width)

    width=height=nil if crop.nil? && !has_layer && !width.to_s.start_with?("auto") && !allow_implicit_crop_mode

    background = options.delete(:background)
    background = background.sub(/^#/, 'rgb:') if background

    color = options.delete(:color)
    color = color.sub(/^#/, 'rgb:') if color

    base_transformations = build_array(options.delete(:transformation))
    if base_transformations.any?{|base_transformation| base_transformation.is_a?(Hash)}
      base_transformations = base_transformations.map do
        |base_transformation|
        base_transformation.is_a?(Hash) ? generate_transformation_string(base_transformation.clone, allow_implicit_crop_mode) : generate_transformation_string({:transformation=>base_transformation}, allow_implicit_crop_mode)
      end
    else
      named_transformation = base_transformations.join(".")
      base_transformations = []
    end

    effect = options.delete(:effect)
    effect = Array(effect).flatten.join(":") if effect.is_a?(Array) || effect.is_a?(Hash)

    border = options.delete(:border)
    if border.is_a?(Hash)
      border = "#{border[:width] || 2}px_solid_#{(border[:color] || "black").sub(/^#/, 'rgb:')}"
    elsif border.to_s =~ /^\d+$/ # fallback to html border attribute
      options[:border] = border
      border = nil
    end
    flags = build_array(options.delete(:flags)).join(".")
    dpr = config_option_consume(options, :dpr)

    if options.include? :offset
      options[:start_offset], options[:end_offset] = split_range options.delete(:offset)
    end

    fps = options.delete(:fps)
    fps = fps.join('-') if fps.is_a? Array

    overlay = process_layer(options.delete(:overlay))
    underlay = process_layer(options.delete(:underlay))
    ifValue = process_if(options.delete(:if))
    custom_function = process_custom_function(options.delete(:custom_function))
    custom_pre_function = process_custom_pre_function(options.delete(:custom_pre_function))

    params = {
      :a   => normalize_expression(angle),
      :ar => normalize_expression(options.delete(:aspect_ratio)),
      :b   => background,
      :bo  => border,
      :c   => crop,
      :co  => color,
      :dpr => normalize_expression(dpr),
      :e   => normalize_expression(effect),
      :fl  => flags,
      :fn  => custom_function || custom_pre_function,
      :fps => fps,
      :h   => normalize_expression(height),
      :l  => overlay,
      :o => normalize_expression(options.delete(:opacity)),
      :q => normalize_expression(options.delete(:quality)),
      :r => process_radius(options.delete(:radius)),
      :t   => named_transformation,
      :u  => underlay,
      :w   => normalize_expression(width),
      :x => normalize_expression(options.delete(:x)),
      :y => normalize_expression(options.delete(:y)),
      :z => normalize_expression(options.delete(:zoom))
    }
    SIMPLE_TRANSFORMATION_PARAMS.each do
      |param, option|
      params[param] = options.delete(option)
    end

    params[:vc] = process_video_params params[:vc] if params[:vc].present?
    [:so, :eo, :du].each do |range_value|
      params[range_value] = norm_range_value params[range_value] if params[range_value].present?
    end

    variables = options.delete(:variables)
    var_params = []
    options.each_pair do |key, value|
      if key =~ /^\$/
        var_params.push "#{key}_#{normalize_expression(value.to_s)}"
      end
    end
    var_params.sort!
    unless variables.nil? || variables.empty?
      for name, value in variables
        var_params.push "#{name}_#{normalize_expression(value.to_s)}"
      end
    end
    variables = var_params.join(',')

    raw_transformation = options.delete(:raw_transformation)
    transformation = params.reject{|_k,v| v.blank?}.map{|k,v| "#{k}_#{v}"}.sort
    transformation = transformation.join(",")
    transformation = [ifValue, variables, transformation, raw_transformation].reject(&:blank?).join(",")

    transformations = base_transformations << transformation
    if responsive_width
      responsive_width_transformation = Cloudinary.config.responsive_width_transformation || DEFAULT_RESPONSIVE_WIDTH_TRANSFORMATION
      transformations << generate_transformation_string(responsive_width_transformation.clone, allow_implicit_crop_mode)
    end

    if width.to_s.start_with?( "auto") || responsive_width
      options[:responsive] = true
    end
    if dpr.to_s == "auto"
      options[:hidpi] = true
    end

    transformations.reject(&:blank?).join("/")
  end

  # Parse "if" parameter
  # Translates the condition if provided.
  # @return [string] "if_" + ifValue
  # @private
  def self.process_if(if_value)
    "if_" + normalize_expression(if_value) unless if_value.to_s.empty?
  end

  EXP_REGEXP = Regexp.new('(\$_*[^_ ]+)|(?<![\$:])('+PREDEFINED_VARS.keys.join("|")+')'+'|('+CONDITIONAL_OPERATORS.keys.reverse.map { |k| Regexp.escape(k) }.join('|')+')(?=[ _])')
  EXP_REPLACEMENT = PREDEFINED_VARS.merge(CONDITIONAL_OPERATORS)

  def self.normalize_expression(expression)
    if expression.nil?
      nil
    elsif expression.is_a?( String) && expression =~ /^!.+!$/ # quoted string
      expression
    else
      expression.to_s.gsub(EXP_REGEXP) { |match| EXP_REPLACEMENT[match] || match }.gsub(/[ _]+/, "_")
    end
  end

  # Parse layer options
  # @return [string] layer transformation string
  # @private
  def self.process_layer(layer)
     if layer.is_a? String and layer.start_with?("fetch:")
      layer = {:url => layer[6..-1]} # omit "fetch:" prefix
     end
     if layer.is_a? Hash
       layer = symbolize_keys layer
       public_id     = layer[:public_id]
       format        = layer[:format]
       fetch         = layer[:url]
       resource_type = layer[:resource_type] || "image"
       type          = layer[:type]
       text          = layer[:text]
       text_style    = nil
       components    = []

       if type.nil?
         if fetch.nil?
           type = "upload"
         else
           type = "fetch"
         end
       end

       if public_id.present?
          if type == "fetch" and public_id.match(%r(^https?:/)i)
            public_id = Base64.urlsafe_encode64(public_id)
          else
            public_id = public_id.gsub("/", ":")
            public_id = "#{public_id}.#{format}" if format
          end
       end

       if fetch.present? && fetch.match(%r(^https?:/)i)
         fetch = Base64.urlsafe_encode64(fetch)
       elsif text.blank? && resource_type != "text"
         if public_id.blank? && type != "fetch"
           raise(CloudinaryException, "Must supply public_id for resource_type layer_parameter")
         end
         if resource_type == "subtitles"
           text_style = text_style(layer)
         end
       else
         resource_type = "text"
         type          = nil
         # // type is ignored for text layers
         text_style    = text_style(layer)
         unless text.blank?
           unless public_id.blank? ^ text_style.blank?
             raise(CloudinaryException, "Must supply either style parameters or a public_id when providing text parameter in a text overlay/underlay")
           end

           result = ""
           # Don't encode interpolation expressions e.g. $(variable)
           while(/\$\([a-zA-Z]\w+\)/.match text) do
             match = Regexp.last_match
             result += smart_escape smart_escape(match.pre_match, %r"([,/])") # append encoded pre-match
             result += match.to_s # append match
             text = match.post_match
           end
           text = result + smart_escape( smart_escape(text, %r"([,/])"))
         end
       end
       components.push(resource_type) if resource_type != "image"
       components.push(type) if type != "upload"
       components.push(text_style)
       components.push(public_id)
       components.push(fetch)
       components.push(text)
       layer = components.reject(&:blank?).join(":")
     end
     layer
  end
  private_class_method :process_layer

  # Parse radius options
  # @return [string] radius transformation string
  # @private
  def self.process_radius(radius)
    if radius.is_a?(Array) && !radius.length.between?(1, 4)
      raise(CloudinaryException, "Invalid radius parameter")
    end
    Array(radius).map { |r| normalize_expression(r) }.join(":")
  end
  private_class_method :process_radius

  LAYER_KEYWORD_PARAMS =[
    [:font_weight     ,"normal"],
    [:font_style      ,"normal"],
    [:text_decoration ,"none"],
    [:text_align      ,nil],
    [:stroke          ,"none"],
  ]

  def self.text_style(layer)
    return layer[:text_style] if layer[:text_style].present?

    font_family = layer[:font_family]
    font_size   = layer[:font_size]
    keywords    = []
    LAYER_KEYWORD_PARAMS.each do |attr, default_value|
      attr_value = layer[attr] || default_value
      keywords.push(attr_value) unless attr_value == default_value
    end
    letter_spacing = layer[:letter_spacing]
    keywords.push("letter_spacing_#{letter_spacing}") unless letter_spacing.blank?
    line_spacing = layer[:line_spacing]
    keywords.push("line_spacing_#{line_spacing}") unless line_spacing.blank?
    font_antialiasing = layer[:font_antialiasing]
    keywords.push("antialias_#{font_antialiasing}") unless font_antialiasing.blank?
    font_hinting = layer[:font_hinting]
    keywords.push("hinting_#{font_hinting}") unless font_hinting.blank?
    if !font_size.blank? || !font_family.blank? || !keywords.empty?
      raise(CloudinaryException, "Must supply font_family for text in overlay/underlay") if font_family.blank?
      raise(CloudinaryException, "Must supply font_size for text in overlay/underlay") if font_size.blank?
      keywords.unshift(font_size)
      keywords.unshift(font_family)
      keywords.reject(&:blank?).join("_")
    end
  end

  def self.api_string_to_sign(params_to_sign)
    params_to_sign.map{|k,v| [k.to_s, v.is_a?(Array) ? v.join(",") : v]}.reject{|k,v| v.nil? || v == ""}.sort_by(&:first).map{|k,v| "#{k}=#{v}"}.join("&")
  end

  def self.api_sign_request(params_to_sign, api_secret, signature_algorithm = nil)
    to_sign = api_string_to_sign(params_to_sign)
    hash("#{to_sign}#{api_secret}", signature_algorithm, :hexdigest)
  end

  # Returns a JSON array as String.
  # Yields the array before it is converted to JSON format
  # @api private
  # @param [Hash|String|Array<Hash>] data
  # @return [String|nil] a JSON array string or `nil` if data is `nil`
  def self.json_array_param(data)
    return nil if data.nil?

    data = JSON.parse(data) if data.is_a?(String)
    data = [data] unless data.is_a?(Array)
    data = yield data if block_given?
    JSON.generate(data)
  end

  def self.generate_responsive_breakpoints_string(breakpoints)
    return nil if breakpoints.nil?
    breakpoints = build_array(breakpoints)

    breakpoints.map do |breakpoint_settings|
      unless breakpoint_settings.nil?
        breakpoint_settings = breakpoint_settings.clone
        transformation =  breakpoint_settings.delete(:transformation) || breakpoint_settings.delete("transformation")
        format =  breakpoint_settings.delete(:format) || breakpoint_settings.delete("format")
        if transformation
          transformation = Cloudinary::Utils.generate_transformation_string(transformation.clone, true)
        end
        breakpoint_settings[:transformation] = [transformation, format].compact.join("/")
      end
      breakpoint_settings
    end.to_json
  end

  # Warning: options are being destructively updated!
  def self.unsigned_download_url(source, options = {})

    patch_fetch_format(options)
    type = options.delete(:type)

    transformation = self.generate_transformation_string(options)

    resource_type = options.delete(:resource_type)
    version = options.delete(:version)
    force_version = config_option_consume(options, :force_version, true)
    format = options.delete(:format)

    shorten = config_option_consume(options, :shorten)
    force_remote = options.delete(:force_remote)

    sign_url = config_option_consume(options, :sign_url)
    secret = config_option_consume(options, :api_secret)
    sign_version = config_option_consume(options, :sign_version) # Deprecated behavior
    url_suffix = options.delete(:url_suffix)
    use_root_path = config_option_consume(options, :use_root_path)
    auth_token = config_option_consume(options, :auth_token)
    long_url_signature = config_option_consume(options, :long_url_signature)
    signature_algorithm = config_option_consume(options, :signature_algorithm)
    unless auth_token == false
      auth_token = Cloudinary::AuthToken.merge_auth_token(Cloudinary.config.auth_token, auth_token)
    end

    original_source = source
    return original_source if source.blank?
    if defined?(CarrierWave::Uploader::Base) && source.is_a?(CarrierWave::Uploader::Base)
      resource_type ||= source.resource_type
      type ||= source.storage_type
      source = format.blank? ? source.filename : source.full_public_id
    end
    type = type.to_s unless type.nil?
    resource_type ||= "image"
    source = source.to_s
    unless force_remote
      static_support = Cloudinary.config.static_file_support || Cloudinary.config.static_image_support
      return original_source if !static_support && type == "asset"
      return original_source if (type.nil? || type == "asset") && source.match(%r(^https?:/)i)
      return original_source if source.match(%r(^/(?!images/).*)) # starts with / but not /images/

      source = source.sub(%r(^/images/), '') # remove /images/ prefix  - backwards compatibility
      if type == "asset"
        source, resource_type = Cloudinary::Static.public_id_and_resource_type_from_path(source)
        return original_source unless source # asset not found in Static
        source += File.extname(original_source) unless format
      end
    end

    resource_type, type = finalize_resource_type(resource_type, type, url_suffix, use_root_path, shorten)
    source, source_to_sign = finalize_source(source, format, url_suffix)

    if version.nil? && force_version &&
         source_to_sign.include?("/") &&
         !source_to_sign.match(/^v[0-9]+/) &&
         !source_to_sign.match(/^https?:\//)
      version = 1
    end
    version &&= "v#{version}"

    transformation = transformation.gsub(%r(([^:])//), '\1/')
    if sign_url && ( !auth_token || auth_token.empty?)
      raise(CloudinaryException, "Must supply api_secret") if (secret.nil? || secret.empty?)
      to_sign = [transformation, sign_version && version, source_to_sign].reject(&:blank?).join("/")
      to_sign = fully_unescape(to_sign)
      signature_algorithm = long_url_signature ? ALGO_SHA256 : signature_algorithm
      hash = hash("#{to_sign}#{secret}", signature_algorithm)
      signature = Base64.urlsafe_encode64(hash)
      signature = "s--#{signature[0, long_url_signature ? LONG_URL_SIGNATURE_LENGTH : SHORT_URL_SIGNATURE_LENGTH ]}--"
    end

    options[:source] = source
    prefix = build_distribution_domain(options)

    source = [prefix, resource_type, type, signature, transformation, version, source].reject(&:blank?).join("/")
    if sign_url && auth_token && !auth_token.empty?
      auth_token[:url] = URI.parse(source).path
      token = Cloudinary::AuthToken.generate auth_token
      source += "?#{token}"
    end

    source
  end

  def self.finalize_source(source, format, url_suffix)
    source = source.gsub(%r(([^:])//), '\1/')
    if source.match(%r(^https?:/)i)
      source = smart_escape(source)
      source_to_sign = source
    else
      source = smart_escape(smart_unescape(source))
      source_to_sign = source
      unless url_suffix.blank?
        raise(CloudinaryException, "url_suffix should not include . or /") if url_suffix.match(%r([\./]))
        source = "#{source}/#{url_suffix}"
      end
      if !format.blank?
        source = "#{source}.#{format}"
        source_to_sign = "#{source_to_sign}.#{format}"
      end
    end
    [source, source_to_sign]
  end

  def self.finalize_resource_type(resource_type, type, url_suffix, use_root_path, shorten)
    type ||= :upload
    if !url_suffix.blank?
      case
      when resource_type.to_s == "image" && type.to_s == "upload"
        resource_type = "images"
        type = nil
      when resource_type.to_s == "image" && type.to_s == "private"
        resource_type = "private_images"
        type = nil
      when resource_type.to_s == "image" && type.to_s == "authenticated"
        resource_type = "authenticated_images"
        type = nil
      when resource_type.to_s == "raw" && type.to_s == "upload"
        resource_type = "files"
        type = nil
      when resource_type.to_s == "video" && type.to_s == "upload"
        resource_type = "videos"
        type = nil
      else
        raise(CloudinaryException, "URL Suffix only supported for image/upload, image/private, image/authenticated, video/upload and raw/upload")
      end
    end
    if use_root_path
      if (resource_type.to_s == "image" && type.to_s == "upload") || (resource_type.to_s == "images" && type.blank?)
        resource_type = nil
        type = nil
      else
        raise(CloudinaryException, "Root path only supported for image/upload")
      end
    end
    if shorten && resource_type.to_s == "image" && type.to_s == "upload"
      resource_type = "iu"
      type = nil
    end
    [resource_type, type]
  end

  # Creates the URL prefix for the cloudinary resource URL
  #
  # cdn_subdomain and secure_cdn_subdomain
  # 1. Customers in shared distribution (e.g. res.cloudinary.com)
  #
  #    if cdn_domain is true uses res-[1-5 ].cloudinary.com for both http and https. Setting secure_cdn_subdomain to false disables this for https.
  # 2. Customers with private cdn
  #
  #    if cdn_domain is true uses cloudname-res-[1-5 ].cloudinary.com for http
  #
  #    if secure_cdn_domain is true uses cloudname-res-[1-5 ].cloudinary.com for https (please contact support if you require this)
  # 3. Customers with cname
  #
  #    if cdn_domain is true uses a\[1-5\]\.cname for http. For https, uses the same naming scheme as 1 for shared distribution and as 2 for private distribution.
  # @private
  def self.unsigned_download_url_prefix(source, cloud_name, private_cdn, cdn_subdomain, secure_cdn_subdomain, cname, secure, secure_distribution)
    return "/res#{cloud_name}" if cloud_name.start_with?("/") # For development

    shared_domain = !private_cdn

    if secure
      if secure_distribution.nil? || secure_distribution == Cloudinary::OLD_AKAMAI_SHARED_CDN
        secure_distribution = private_cdn ? "#{cloud_name}-res.cloudinary.com" : Cloudinary::SHARED_CDN
      end
      shared_domain ||= secure_distribution == Cloudinary::SHARED_CDN
      secure_cdn_subdomain = cdn_subdomain if secure_cdn_subdomain.nil? && shared_domain

      if secure_cdn_subdomain
        secure_distribution = secure_distribution.gsub('res.cloudinary.com', "res-#{(Zlib::crc32(source) % 5) + 1}.cloudinary.com")
      end

      prefix = "https://#{secure_distribution}"
    elsif cname
      subdomain = cdn_subdomain ? "a#{(Zlib::crc32(source) % 5) + 1}." : ""
      prefix = "http://#{subdomain}#{cname}"
    else
      host = [private_cdn ? "#{cloud_name}-" : "", "res", cdn_subdomain ? "-#{(Zlib::crc32(source) % 5) + 1}" : "", ".cloudinary.com"].join
      prefix = "http://#{host}"
    end
    prefix += "/#{cloud_name}" if shared_domain

    prefix
  end

  def self.build_distribution_domain(options = {})
    cloud_name = config_option_consume(options, :cloud_name) || raise(CloudinaryException, "Must supply cloud_name in tag or in configuration")

    source = options.delete(:source)
    secure = options.delete(:secure)
    ssl_detected = options.delete(:ssl_detected)
    secure = ssl_detected || Cloudinary.config.secure if secure.nil?
    private_cdn = config_option_consume(options, :private_cdn)
    secure_distribution = config_option_consume(options, :secure_distribution)
    cname = config_option_consume(options, :cname)
    cdn_subdomain = config_option_consume(options, :cdn_subdomain)
    secure_cdn_subdomain = config_option_consume(options, :secure_cdn_subdomain)

    unsigned_download_url_prefix(source, cloud_name, private_cdn, cdn_subdomain, secure_cdn_subdomain, cname, secure, secure_distribution)
  end

  # Creates a base URL for the cloudinary api
  #
  # @param [Object] path  Resource name
  # @param [Hash] options Additional options
  #
  # @return [String]
  def self.base_api_url(path, options = {})
    cloudinary = options[:upload_prefix] || Cloudinary.config.upload_prefix || UPLOAD_PREFIX
    cloud_name = options[:cloud_name] || Cloudinary.config.cloud_name || raise(CloudinaryException, 'Must supply cloud_name')

    [cloudinary, 'v1_1', cloud_name, path].join('/')
  end

  def self.cloudinary_api_url(action = 'upload', options = {})
    resource_type = options[:resource_type] || 'image'

    base_api_url([resource_type, action], options)
  end

  def self.sign_request(params, options={})
    api_key = options[:api_key] || Cloudinary.config.api_key || raise(CloudinaryException, "Must supply api_key")
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise(CloudinaryException, "Must supply api_secret")
    signature_algorithm = options[:signature_algorithm]
    params = params.reject{|k, v| self.safe_blank?(v)}
    params[:signature] = api_sign_request(params, api_secret, signature_algorithm)
    params[:api_key] = api_key
    params
  end

  # Helper method for generating download URLs
  #
  # @param [String] action @see Cloudinary::Utils.cloudinary_api_url
  # @param [Hash] params Query parameters in generated URL
  # @param [Hash] options Additional options
  # @yield [query_parameters] Invokes the block with query parameters to override how to encode them
  #
  # @return [String]
  def self.cloudinary_api_download_url(action, params, options = {})
    cloudinary_params = sign_request(params.merge(mode: MODE_DOWNLOAD), options)

    "#{Cloudinary::Utils.cloudinary_api_url(action, options)}?#{hash_query_params(cloudinary_params)}"
  end
  private_class_method :cloudinary_api_download_url

  # Return a signed URL to the 'generate_sprite' endpoint with 'mode=download'.
  #
  # @param [String|Hash] tag Treated as additional options when hash is passed, otherwise as a tag
  # @param [Hash] options Additional options. Should be omitted when +tag_or_options+ is a Hash
  #
  # @return [String] The signed URL to download sprite
  def self.download_generated_sprite(tag, options = {})
    params = build_multi_and_sprite_params(tag, options)
    cloudinary_api_download_url("sprite", params, options)
  end

  # Return a signed URL to the 'multi' endpoint with 'mode=download'.
  #
  # @param [String|Hash] tag Treated as additional options when hash is passed, otherwise as a tag
  # @param [Hash] options Additional options. Should be omitted when +tag_or_options+ is a Hash
  #
  # @return [String] The signed URL to download multi
  def self.download_multi(tag, options = {})
    params = build_multi_and_sprite_params(tag, options)
    cloudinary_api_download_url("multi", params, options)
  end

  def self.private_download_url(public_id, format, options = {})
    cloudinary_params = sign_request({
        :timestamp=>Time.now.to_i,
        :public_id=>public_id,
        :format=>format,
        :type=>options[:type],
        :attachment=>options[:attachment],
        :expires_at=>options[:expires_at] && options[:expires_at].to_i
      }, options)

    return Cloudinary::Utils.cloudinary_api_url("download", options) + "?" + hash_query_params(cloudinary_params)
  end

  # Utility method that uses the deprecated ZIP download API.
  # @deprecated Replaced by {download_zip_url} that uses the more advanced and robust archive generation and download API
  def self.zip_download_url(tag, options = {})
    warn "zip_download_url is deprecated. Please use download_zip_url instead."
    cloudinary_params = sign_request({:timestamp=>Time.now.to_i, :tag=>tag, :transformation=>generate_transformation_string(options)}, options)
    return Cloudinary::Utils.cloudinary_api_url("download_tag.zip", options) + "?" + hash_query_params(cloudinary_params)
  end

  # Returns a URL that when invokes creates an archive and returns it.
  # @param options [Hash]
  # @option options [String|Symbol] :resource_type  The resource type of files to include in the archive. Must be one of :image | :video | :raw
  # @option options [String|Symbol] :type (:upload) The specific file type of resources: :upload|:private|:authenticated
  # @option options [String|Symbol|Array] :tags (nil) list of tags to include in the archive
  # @option options [String|Array<String>] :public_ids (nil) list of public_ids to include in the archive
  # @option options [String|Array<String>] :prefixes (nil) Optional list of prefixes of public IDs (e.g., folders).
  # @option options [String|Array<String>] :transformations Optional list of transformations.
  #   The derived images of the given transformations are included in the archive. Using the string representation of
  #   multiple chained transformations as we use for the 'eager' upload parameter.
  # @option options [String|Symbol] :mode (:create) return the generated archive file or to store it as a raw resource and
  #   return a JSON with URLs for accessing the archive. Possible values: :download, :create
  # @option options [String|Symbol] :target_format (:zip)
  # @option options [String] :target_public_id Optional public ID of the generated raw resource.
  #   Relevant only for the create mode. If not specified, random public ID is generated.
  # @option options [boolean] :flatten_folders (false) If true, flatten public IDs with folders to be in the root of the archive.
  #   Add numeric counter to the file name in case of a name conflict.
  # @option options [boolean] :flatten_transformations (false) If true, and multiple transformations are given,
  #   flatten the folder structure of derived images and store the transformation details on the file name instead.
  # @option options [boolean] :use_original_filename Use the original file name of included images (if available) instead of the public ID.
  # @option options [boolean] :async (false) If true, return immediately and perform the archive creation in the background.
  #   Relevant only for the create mode.
  # @option options [String] :notification_url Optional URL to send an HTTP post request (webhook) when the archive creation is completed.
  # @option options [String|Array<String] :target_tags Optional array. Allows assigning one or more tag to the generated archive file (for later housekeeping via the admin API).
  # @option options [String] :keep_derived (false) keep the derived images used for generating the archive
  # @return [String] archive url
  def self.download_archive_url(options = {})
    params = Cloudinary::Utils.archive_params(options)
    cloudinary_api_download_url("generate_archive", params, options)
  end

  # Returns a URL that when invokes creates an zip archive and returns it.
  # @see download_archive_url
  def self.download_zip_url(options = {})
    download_archive_url(options.merge(:target_format => "zip"))
  end

  # Creates and returns a URL that when invoked creates an archive of a folder.
  #
  # @param [Object] folder_path Full path (from the root) of the folder to download.
  # @param [Hash] options       Additional options.
  #
  # @return [String]
  def self.download_folder(folder_path, options = {})
    resource_type = options[:resource_type] || "all"

    download_archive_url(options.merge(:resource_type => resource_type, :prefixes => folder_path))
  end

  def self.signed_download_url(public_id, options = {})
    aws_private_key_path = options[:aws_private_key_path] || Cloudinary.config.aws_private_key_path
    if aws_private_key_path
      aws_key_pair_id = options[:aws_key_pair_id] || Cloudinary.config.aws_key_pair_id || raise(CloudinaryException, "Must supply aws_key_pair_id")
      authenticated_distribution = options[:authenticated_distribution] || Cloudinary.config.authenticated_distribution || raise(CloudinaryException, "Must supply authenticated_distribution")
      @signers ||= Hash.new{|h,k| path, id = k; h[k] = AwsCfSigner.new(path, id)}
      signer = @signers[[aws_private_key_path, aws_key_pair_id]]
      url = Cloudinary::Utils.unsigned_download_url(public_id, {:type=>:authenticated}.merge(options).merge(:secure=>true, :secure_distribution=>authenticated_distribution, :private_cdn=>true))
      expires_at = options[:expires_at] || (Time.now+3600)
      return signer.sign(url, :ending => expires_at)
    else
      return Cloudinary::Utils.unsigned_download_url( public_id, options)
    end

  end

  def self.cloudinary_url(public_id, options = {})
    if options[:type].to_s == 'authenticated' && !options[:sign_url]
      result = signed_download_url(public_id, options)
    else
      result = unsigned_download_url(public_id, options)
    end
    return result
  end

  def self.asset_file_name(path)
    data = Cloudinary.app_root.join(path).read(:mode=>"rb")
    ext = path.extname
    md5 = Digest::MD5.hexdigest(data)
    public_id = "#{path.basename(ext)}-#{md5}"
    "#{public_id}#{ext}"
  end

  # Based on CGI::escape. In addition does not escape / :
  def self.smart_escape(string, unsafe = /([^a-zA-Z0-9_.\-\/:]+)/)
    string.gsub(unsafe) do |m|
      '%' + m.unpack('H2' * m.bytesize).join('%').upcase
    end
  end

  # Based on CGI::unescape. In addition keeps '+' character as is
  def self.smart_unescape(string)
    CGI.unescape(string.gsub('+', '%2B'))
  end

  def self.random_public_id
    sr = defined?(ActiveSupport::SecureRandom) ? ActiveSupport::SecureRandom : SecureRandom
    sr.base64(20).downcase.gsub(/[^a-z0-9]/, "").sub(/^[0-9]+/, '')[0,20]
  end

  def self.signed_preloaded_image(result)
    "#{result["resource_type"]}/#{result["type"] || "upload"}/v#{result["version"]}/#{[result["public_id"], result["format"]].reject(&:blank?).join(".")}##{result["signature"]}"
  end

  @@json_decode = false
  def self.json_decode(str)
    if !@@json_decode
      @@json_decode = true
      begin
        require 'json'
      rescue LoadError
        begin
          require 'active_support/json'
        rescue LoadError
          raise LoadError, "Please add the json gem or active_support to your Gemfile"
        end
      end
    end
    defined?(JSON) ? JSON.parse(str) : ActiveSupport::JSON.decode(str)
  end

  def self.build_array(array)
    case array
      when Array then array
      when nil then []
      else [array]
    end
  end

  # encodes a hash into pipe-delimited key-value pairs string
  # @hash [Hash] key-value hash to be encoded
  # @return [String] a joined string of all keys and values separated by a pipe character
  # @private
  def self.encode_hash(hash)
    case hash
      when Hash then hash.map{|k,v| "#{k}=#{v}"}.join("|")
      when nil then ""
      else hash
    end
  end

  # Same like encode_hash, with additional escaping of | and = characters
  # @hash [Hash] key-value hash to be encoded
  # @return [String] a joined string of all keys and values properly escaped and separated by a pipe character
  # @private
  def self.encode_context(hash)
    case hash
      when Hash then hash.map{|k,v| "#{k}=#{v.to_s.gsub(/([=|])/, '\\\\\1')}"}.join("|")
      when nil then ""
      else hash
    end
  end

  def self.encode_double_array(array)
    array = build_array(array)
    if array.length > 0 && array[0].is_a?(Array)
      return array.map{|a| build_array(a).join(",")}.join("|")
    else
      return array.join(",")
    end
  end

  IMAGE_FORMATS = %w(ai bmp bpg djvu eps eps3 flif gif hdp hpx ico j2k jp2 jpc jpe jpeg jpg miff pdf png psd svg tif tiff wdp webp zip )

  AUDIO_FORMATS = %w(aac aifc aiff flac m4a mp3 ogg wav)

  VIDEO_FORMATS = %w(3g2 3gp asf avi flv h264 m2t m2v m3u8 mka mov mp4 mpeg ogv ts webm wmv )

  def self.supported_image_format?(format)
    supported_format? format, IMAGE_FORMATS
  end

  def self.supported_format?( format, formats)
    format = format.to_s.downcase
    extension = format =~ /\./ ? format.split('.').last : format
    formats.include?(extension)
  end

  def self.resource_type_for_format(format)
    case
    when self.supported_format?(format, IMAGE_FORMATS)
      'image'
    when self.supported_format?(format, VIDEO_FORMATS), self.supported_format?(format, AUDIO_FORMATS)
      'video'
    else
      'raw'
    end
  end

  def self.config_option_consume(options, option_name, default_value = nil)
    return options.delete(option_name) if options.include?(option_name)
    option_value = Cloudinary.config.send(option_name)
    option_value.nil? ? default_value : option_value
  end

  def self.config_option_fetch(options, option_name, default_value = nil)
    return options.fetch(option_name) if options.include?(option_name)
    option_value = Cloudinary.config.send(option_name)
    option_value.nil? ? default_value : option_value
  end

  def self.as_bool(value)
    case value
    when nil then nil
    when String then value.downcase == "true" || value == "1"
    when TrueClass then true
    when FalseClass then false
    when Integer then value != 0
    when Symbol then value == :true
    else
      raise "Invalid boolean value #{value} of type #{value.class}"
    end
  end

  def self.as_safe_bool(value)
    case as_bool(value)
    when nil then nil
    when TrueClass then 1
    when FalseClass then 0
    end
  end

  def self.safe_blank?(value)
    value.nil? || value == "" || value == []
  end

  def self.symbolize_keys(h)
    new_h = Hash.new
    if (h.respond_to? :keys)
      h.keys.each do |key|
        new_h[(key.to_sym rescue key)] = h[key]
      end
    end
    new_h
  end


  def self.symbolize_keys!(h)
    if (h.respond_to? :keys) && (h.respond_to? :delete)
      h.keys.each do |key|
        value = h.delete(key)
        h[(key.to_sym rescue key)] = value
      end
    end
    h
  end


  def self.deep_symbolize_keys(object)
    case object
    when Hash
      result = {}
      object.each do |key, value|
        key = key.to_sym rescue key
        result[key] = deep_symbolize_keys(value)
      end
      result
    when Array
      object.map{|e| deep_symbolize_keys(e)}
    else
      object
    end
  end

  # Returns a Hash of parameters used to create an archive
  # @param [Hash] options
  # @private
  def self.archive_params(options = {})
    options = Cloudinary::Utils.symbolize_keys options
    {
      :timestamp=>(options[:timestamp] || Time.now.to_i),
      :type=>options[:type],
      :mode => options[:mode],
      :target_format => options[:target_format],
      :target_public_id=> options[:target_public_id],
      :flatten_folders=>Cloudinary::Utils.as_safe_bool(options[:flatten_folders]),
      :flatten_transformations=>Cloudinary::Utils.as_safe_bool(options[:flatten_transformations]),
      :use_original_filename=>Cloudinary::Utils.as_safe_bool(options[:use_original_filename]),
      :async=>Cloudinary::Utils.as_safe_bool(options[:async]),
      :notification_url=>options[:notification_url],
      :target_tags=>options[:target_tags] && Cloudinary::Utils.build_array(options[:target_tags]),
      :keep_derived=>Cloudinary::Utils.as_safe_bool(options[:keep_derived]),
      :tags=>options[:tags] && Cloudinary::Utils.build_array(options[:tags]),
      :public_ids=>options[:public_ids] && Cloudinary::Utils.build_array(options[:public_ids]),
      :fully_qualified_public_ids=>options[:fully_qualified_public_ids] && Cloudinary::Utils.build_array(options[:fully_qualified_public_ids]),
      :prefixes=>options[:prefixes] && Cloudinary::Utils.build_array(options[:prefixes]),
      :expires_at=>options[:expires_at],
      :transformations => build_eager(options[:transformations]),
      :skip_transformation_name=>Cloudinary::Utils.as_safe_bool(options[:skip_transformation_name]),
      :allow_missing=>Cloudinary::Utils.as_safe_bool(options[:allow_missing])
    }
  end

  #
  # @private
  # @param [String|Hash|Array] eager an transformation as a string or hash, with or without a format. The parameter also accepts an array of eager transformations.
  def self.build_eager(eager)
    return nil if eager.nil?
    Cloudinary::Utils.build_array(eager).map do
    |transformation, format|
      unless transformation.is_a? String
        transformation = transformation.clone
        if transformation.respond_to?(:delete)
          format = transformation.delete(:format) || format
        end
        transformation = Cloudinary::Utils.generate_transformation_string(transformation, true)
      end
      [transformation, format].compact.join("/")
    end.join("|")
  end

  def self.generate_auth_token(options)
    options = Cloudinary::AuthToken.merge_auth_token Cloudinary.config.auth_token, options
    Cloudinary::AuthToken.generate options

  end

  private


  # Repeatedly unescapes the source until no more unescaping is possible or 10 cycles elapsed
  # @param [String] source - a (possibly) escaped string
  # @return [String] the fully unescaped string
  # @private
  def self.fully_unescape(source)
    i = 0
    while source != CGI.unescape(source.gsub('+', '%2B')) && i <10
      source = CGI.unescape(source.gsub('+', '%2B')) # don't let unescape replace '+' with space
      i = i + 1
    end
    source
  end
  private_class_method :fully_unescape

  def self.hash_query_params(hash)
    if hash.respond_to?("to_query")
      hash.to_query
    else
      flat_hash_to_query_params(hash)
    end
  end

  def self.flat_hash_to_query_params(hash)
    hash.collect do |key, value|
      if value.is_a?(Array)
        value.map{|v| "#{CGI.escape(key.to_s)}[]=#{CGI.escape(v.to_s)}"}.join("&")
      else
        "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end
    end.compact.sort!.join('&')
  end

  def self.number_pattern
    "([0-9]*)\\.([0-9]+)|([0-9]+)"
  end
  private_class_method :number_pattern

  def self.offset_any_pattern
    "(#{number_pattern})([%pP])?"
  end
  private_class_method :offset_any_pattern

  def self.offset_any_pattern_re
    /((([0-9]*)\.([0-9]+)|([0-9]+))([%pP])?)\.\.((([0-9]*)\.([0-9]+)|([0-9]+))([%pP])?)/
  end
  private_class_method :offset_any_pattern_re

  # Split a range into the start and end values
  def self.split_range(range) # :nodoc:
    case range
    when Range
      [range.first, range.last]
    when String
      range.split ".." if offset_any_pattern_re =~ range
    when Array
      [range.first, range.last]
    else
      nil
    end
  end
  private_class_method :split_range

  # Normalize an offset value
  # @param [String] value a decimal value which may have a 'p' or '%' postfix. E.g. '35%', '0.4p'
  # @return [Object|String] a normalized String of the input value if possible otherwise the value itself
  # @private
  def self.norm_range_value(value) # :nodoc:
    offset = /^#{offset_any_pattern}$/.match( value.to_s)

    if offset
      modifier = offset[5].present? ? 'p' : ''
      "#{offset[1]}#{modifier}"
    else
      normalize_expression(value)
    end
  end
  private_class_method :norm_range_value

  # A video codec parameter can be either a String or a Hash.
  #
  # @param [Object] param <code>vc_<codec>[ : <profile> : [<level> : [<b_frames>]]]</code>
  #                       or <code>{ codec: 'h264', profile: 'basic', level: '3.1' }</code>
  #                       or <code>{ codec: 'h265', profile: 'auto', level: 'auto', b_frames: false }</code>
  # @return [String] <code><codec> : <profile> : [<level> : [<b_frames>]]]</code> if a Hash was provided
  #                   or the param if a String was provided.
  #                   Returns NIL if param is not a Hash or String
  # @private
  def self.process_video_params(param)
    case param
    when Hash
      video = ""
      if param.has_key? :codec
        video = param[:codec]
        if param.has_key? :profile
          video.concat ":" + param[:profile]
          if param.has_key? :level
            video.concat ":" + param[:level]
            if param.has_key?(:b_frames) && param[:b_frames] === false
              video.concat ":bframes_no"
            end
          end
        end
      end
      video
    when String
      param
    else
      nil
    end
  end
  private_class_method :process_video_params

  def self.process_custom_pre_function(param)
    value = process_custom_function(param)
    value ? "pre:#{value}" : nil
  end

  def self.process_custom_function(param)
    return param unless param.is_a? Hash

    function_type = param[:function_type]
    source = param[:source]

    source = Base64.urlsafe_encode64(source) if function_type == "remote"
    "#{function_type}:#{source}"
  end

  #
  # Handle the format parameter for fetch urls
  # @private
  # @param options url and transformation options. This argument may be changed by the function!
  #
  def self.patch_fetch_format(options={})
    use_fetch_format = config_option_consume(options, :use_fetch_format)
    if options[:type] === :fetch || use_fetch_format
      format_arg = options.delete(:format)
      options[:fetch_format] ||= format_arg
    end
  end

  def self.is_remote?(url)
    REMOTE_URL_REGEX === url
  end

  # Build params for multi, download_multi, generate_sprite, and download_generated_sprite methods
  #
  # @param [String|Hash] tag_or_options Treated as additional options when hash is passed, otherwise as a tag
  # @param [Hash] options Additional options. Should be omitted when +tag_or_options+ is a Hash
  #
  # @return [Hash]
  #
  # @private
  def self.build_multi_and_sprite_params(tag_or_options, options)
    if tag_or_options.is_a?(Hash)
      if options.blank?
        options = tag_or_options
        tag_or_options = nil
      else
        raise "First argument must be a tag when additional options are passed"
      end
    end
    urls = options.delete(:urls)

    if tag_or_options.blank? && urls.blank?
      raise "Either tag or urls are required"
    end

    {
      :tag => tag_or_options,
      :urls => urls,
      :transformation => Cloudinary::Utils.generate_transformation_string(options.merge(:fetch_format => options[:format])),
      :notification_url => options[:notification_url],
      :format => options[:format],
      :async => options[:async],
      :mode => options[:mode],
      :timestamp => (options[:timestamp] || Time.now.to_i)
    }
  end

  # Handles file parameter.
  #
  # @param [Pathname, StringIO, File, String, int, _ToPath] file
  # @return [StringIO, File] A File object.
  #
  # @private
  def self.handle_file_param(file, options = {})
    if file.is_a?(Pathname)
      return File.open(file, "rb")
    elsif file.is_a?(Cloudinary::Blob)
      return file
    elsif file.is_a?(StringIO)
      file.rewind
      return Cloudinary::Blob.new(file.read, options)
    elsif file.respond_to?(:read) || Cloudinary::Utils.is_remote?(file)
      return file
    end

    File.open(file, "rb")
  end

  # The returned url should allow downloading the backedup asset based on the version and asset id
  #
  # asset and version id are returned with resource(<PUBLIC_ID1>, { versions: true })
  #
  # @param [String] asset_id   Asset identifier
  # @param [String] version_id Specific version of asset to download
  # @param [Hash] options      Additional options
  #
  # @return [String] An url for downloading a file
  def self.download_backedup_asset(asset_id, version_id, options = {})
    params = Cloudinary::Utils.sign_request({
      :timestamp => (options[:timestamp] || Time.now.to_i),
      :asset_id => asset_id,
      :version_id => version_id
    }, options)

    "#{Cloudinary::Utils.base_api_url("download_backup", options)}?#{Cloudinary::Utils.hash_query_params((params))}"
  end

  # Format date in a format accepted by the usage API (e.g., 31-12-2020) if
  # passed value is of type Date, otherwise return the string representation of
  # the input.
  #
  # @param [Date|Object] date
  # @return [String]
  def self.to_usage_api_date_format(date)
    if date.is_a?(Date)
      date.strftime('%d-%m-%Y')
    else
      date.to_s
    end
  end

  # Verifies the authenticity of an API response signature.
  #
  # @param [String] public_id he public id of the asset as returned in the API response
  # @param [Fixnum] version The version of the asset as returned in the API response
  # @param [String] signature Actual signature. Can be retrieved from the X-Cld-Signature header
  # @param [Symbol|nil] signature_algorithm Algorithm to use for computing hash
  # @param [Hash] options
  # @option options [String] :api_secret API secret, if not passed taken from global config
  #
  # @return [Boolean]
  def self.verify_api_response_signature(public_id, version, signature, signature_algorithm = nil, options = {})
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise("Must supply api_secret")

    parameters_to_sign = {
      :public_id => public_id,
      :version => version
    }

    signature == api_sign_request(parameters_to_sign, api_secret, signature_algorithm)
  end

  # Verifies the authenticity of a notification signature.
  #
  # @param [String] body JSON of the request's body
  # @param [Fixnum] timestamp Unix timestamp. Can be retrieved from the X-Cld-Timestamp header
  # @param [String] signature Actual signature. Can be retrieved from the X-Cld-Signature header
  # @param [Fixnum] valid_for The desired time in seconds for considering the request valid
  # @param [Symbol|nil] signature_algorithm Algorithm to use for computing hash
  # @param [Hash] options
  # @option options [String] :api_secret API secret, if not passed taken from global config
  #
  # @return [Boolean]
  def self.verify_notification_signature(body, timestamp, signature, valid_for = 7200, signature_algorithm = nil, options = {})
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise("Must supply api_secret")
    raise("Body should be of String type") unless body.is_a?(String)
    # verify that signature is valid for the given timestamp
    return false if timestamp < (Time.now - valid_for).to_i

    payload_hash = hash("#{body}#{timestamp}#{api_secret}", signature_algorithm, :hexdigest)

    signature == payload_hash
  end

  # Computes hash from input string using specified algorithm.
  #
  # @param [String] input                   String which to compute hash from
  # @param [Symbol|nil] signature_algorithm Algorithm to use for computing hash
  # @param [Symbol] hash_method             Hash method applied to a signature algorithm (:digest or :hexdigest)
  #
  # @return [String] Computed hash value
  def self.hash(input, signature_algorithm = nil, hash_method = :digest)
    signature_algorithm ||= Cloudinary.config.signature_algorithm || ALGO_SHA1
    algorithm = ALGORITHM_SIGNATURE[signature_algorithm] || raise("Unsupported algorithm '#{signature_algorithm}'")
    algorithm.public_send(hash_method, input)
  end
end
