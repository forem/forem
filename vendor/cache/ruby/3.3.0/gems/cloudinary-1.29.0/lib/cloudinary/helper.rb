require 'digest/md5'
require 'cloudinary/video_helper'
require 'cloudinary/responsive'

module CloudinaryHelper
  include ActionView::Helpers::CaptureHelper
  include Responsive

  CL_BLANK = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"

  # Stand-in for Rails image_tag helper that accepts various options for transformations.
  #
  # source:: the public ID, possibly with a file type extension.  If there is no extension, the
  #          :format option is expected to indicate what the extension is.  This value can contain
  #          the version, or not.
  # options:: Options you would normally pass to image_tag as well as Cloudinary-specific options
  #           to control the transformation.  Depending on what options are provided, the
  #           generated URL may or may not have Cloudinary-specific details in it.  For example, if
  #           you only specify :width and :height, these values will not be sent to Cloudinary, however
  #           if you also specify :crop, they will be.
  #
  # Examples
  #     # Image tag sized by the browser, not Cloudinary
  #     cl_image_tag "sample.png", :width=>100, :height=>100, :alt=>"hello" # W/H are not sent to Cloudinary
  #
  #     # Image tag sized by Cloudinary using the :fit crop strategy
  #     cl_image_tag "sample.png", :width=>100, :height=>100, :alt=>"hello", :crop=>:fit # W/H are sent to Cloudinary
  #
  #     Get a url for the image with the public id "sample", in :png format.
  #     cl_image_tag "sample", format: :png
  #
  # See documentation for more details and options: http://cloudinary.com/documentation/rails_image_manipulation
  def cl_image_tag(source, options = {})
    cloudinary_tag source, options do |source, options|
      if source
        image_tag_without_cloudinary(source, options)
      else
        tag 'img', options
      end
    end

  end


  def cl_picture_tag(source, options = {}, sources =[])

    options = options.clone
    content_tag 'picture' do
      sources.map do |source_def|
        source_options = options.clone
        source_options = Cloudinary::Utils.chain_transformation(source_options, source_def[:transformation])
        source_options[:media] = source_def
        cl_source_tag(source, source_options)
      end.push(cl_image_tag(source, options))
          .join('')
          .html_safe
    end
  end

  def cl_source_tag(source, options)
    srcset_param = options.fetch(:srcset, {}).merge(Cloudinary.config.srcset || {})
    attributes = options.fetch(:attributes, {}).clone
    responsive_attributes = generate_image_responsive_attributes(source, attributes, srcset_param, options)
    attributes = attributes.merge(responsive_attributes)
    unless attributes.has_key? :srcset
      attributes[:srcset] = Cloudinary::Utils.cloudinary_url(source, options)
    end
    media_attr = generate_media_attribute(options[:media])
    attributes[:media] = media_attr unless media_attr.empty?
    tag "source", attributes, true
  end


  def cloudinary_tag(source, options = {})
    tag_options = options.clone
    tag_options[:width] = tag_options.delete(:html_width) if tag_options.include?(:html_width)
    tag_options[:height] = tag_options.delete(:html_height) if tag_options.include?(:html_height)
    tag_options[:size] = tag_options.delete(:html_size) if tag_options.include?(:html_size)
    tag_options[:border] = tag_options.delete(:html_border) if tag_options.include?(:html_border)
    srcset_param = Cloudinary::Utils.config_option_consume(tag_options, :srcset, {})
    src = cloudinary_url_internal(source, tag_options)
    attributes = tag_options.delete(:attributes) || {}

    responsive_placeholder = Cloudinary::Utils.config_option_consume(tag_options, :responsive_placeholder)
    client_hints = Cloudinary::Utils.config_option_consume(tag_options, :client_hints)

    hidpi = tag_options.delete(:hidpi)
    responsive = tag_options.delete(:responsive)
    if !client_hints && (hidpi || responsive)
      tag_options["data-src"] = src
      src = nil
      extra_class = responsive ? "cld-responsive" : "cld-hidpi"
      tag_options[:class] = [tag_options[:class], extra_class].compact.join(" ")
      responsive_placeholder = CL_BLANK if responsive_placeholder == "blank"
      tag_options[:src] = responsive_placeholder
    end
    responsive_attrs = generate_image_responsive_attributes(source, attributes, srcset_param, options)
    unless  responsive_attrs.empty?
      tag_options.delete(:width)
      tag_options.delete(:height)
      tag_options.merge! responsive_attrs
    end
    if block_given?
      yield(src,tag_options)
    else
      tag('div', tag_options)
    end
  end

  def cl_blank
    CL_BLANK
  end

  # Works similarly to cl_image_tag, however just generates the URL of the image
  def cl_image_path(source, options = {})
    options = options.clone
    url = cloudinary_url_internal(source, options)
    image_path_without_cloudinary(url)
  end
  alias_method :cl_path, :cl_image_path

  def image_tag_with_cloudinary(*args)
    source, options = args
    cl_image_tag(source, {:type=>:asset}.merge(options || {}))
  end

  def image_path_with_cloudinary(*args)
    source, options = args
    cl_image_path(source, {:type=>:asset}.merge(options || {}))
  end

  def fetch_image_tag(profile, options = {})
    cl_image_tag(profile, {:type=>:fetch}.merge(options))
  end

  def facebook_profile_image_tag(profile, options = {})
    cl_image_tag(profile, {:type=>:facebook}.merge(options))
  end

  def facebook_profile_image_path(profile, options = {})
    cl_image_path(profile, {:type=>:facebook}.merge(options))
  end

  def gravatar_profile_image_tag(email, options = {})
    cl_image_tag(Digest::MD5.hexdigest(email.strip.downcase), {:type=>:gravatar, :format=>:jpg}.merge(options))
  end

  def gravatar_profile_image_path(email, options = {})
    cl_image_path(Digest::MD5.hexdigest(email.strip.downcase), {:type=>:gravatar, :format=>:jpg}.merge(options))
  end

  def twitter_profile_image_tag(profile, options = {})
    cl_image_tag(profile, {:type=>:twitter}.merge(options))
  end

  def twitter_profile_image_path(profile, options = {})
    cl_image_path(profile, {:type=>:twitter}.merge(options))
  end

  def twitter_name_profile_image_tag(profile, options = {})
    cl_image_tag(profile, {:type=>:twitter_name}.merge(options))
  end

  def twitter_name_profile_image_path(profile, options = {})
    cl_image_path(profile, {:type=>:twitter_name}.merge(options))
  end

  def gplus_profile_image_tag(profile, options = {})
    cl_image_tag(profile, {:type=>:gplus}.merge(options))
  end

  def gplus_profile_image_path(profile, options = {})
    cl_image_path(profile, {:type=>:gplus}.merge(options))
  end

  def cl_sprite_url(source, options = {})
    options = options.clone

    version_store = options.delete(:version_store)
    if options[:version].blank? && (version_store == :file) && defined?(Rails) && defined?(Rails.root)
      file_name = "#{Rails.root}/tmp/cloudinary/cloudinary_sprite_#{source.sub(/\..*/, '')}.version"
      if File.exists?(file_name)
        options[:version] = File.read(file_name).chomp
      end
    end

    options[:format] = "css" unless source.ends_with?(".css")
    cloudinary_url_internal(source, options.merge(:type=>:sprite))
  end

  def cl_sprite_tag(source, options = {})
    stylesheet_link_tag(cl_sprite_url(source, options))
  end

  # cl_form_tag was originally contributed by Milovan Zogovic
  def cl_form_tag(callback_url, options={}, &block)
    form_options = options.delete(:form) || {}
    form_options[:method] = :post
    form_options[:multipart] = true

    params = Cloudinary::Uploader.build_upload_params(options.merge(:callback=>callback_url))
    params[:signature] = Cloudinary::Utils.api_sign_request(params, Cloudinary.config.api_secret)
    params[:api_key] = Cloudinary.config.api_key

    api_url = Cloudinary::Utils.cloudinary_api_url("upload",
                {:resource_type => options.delete(:resource_type), :upload_prefix => options.delete(:upload_prefix)})

    form_tag(api_url, form_options) do
      content = []

      params.each do |name, value|
        content << hidden_field_tag(name, value, :id => nil) if value.present?
      end

      content << capture(&block)

      content.join("\n").html_safe
    end
  end

  CLOUDINARY_JS_CONFIG_PARAMS = [:api_key, :cloud_name, :private_cdn, :secure_distribution, :cdn_subdomain]
  def cloudinary_js_config
    params = {}
    CLOUDINARY_JS_CONFIG_PARAMS.each do
      |param|
      value = Cloudinary.config.send(param)
      params[param] = value if !value.nil?
    end
    content_tag("script", "$.cloudinary.config(#{params.to_json});".html_safe, :type=>"text/javascript")
  end

  def cl_client_hints_meta_tag
    tag "meta", "http-equiv" => "Accept-CH", :content => "DPR, Viewport-Width, Width"
  end
  def cloudinary_url(source, options = {})
    cloudinary_url_internal(source, options.clone)
  end

  def cl_image_upload(object_name, method, options={})
    cl_image_upload_tag("#{object_name}[#{method}]", options)
  end
  alias_method :cl_upload, :cl_image_upload
  def cl_unsigned_image_upload(object_name, method, upload_preset, options={})
    cl_unsigned_image_upload_tag("#{object_name}[#{method}]", upload_preset, options)
  end
  alias_method :cl_unsigned_upload, :cl_unsigned_image_upload

  def cl_upload_url(options={})
    Cloudinary::Utils.cloudinary_api_url("upload", {:resource_type=>:auto}.merge(options))
  end

  def cl_upload_tag_params(options={})
    cloudinary_params = Cloudinary::Uploader.build_upload_params(options)
    cloudinary_params[:callback] = build_callback_url(options)
    if options[:unsigned]
      return cloudinary_params.reject{|k, v| Cloudinary::Utils.safe_blank?(v)}.to_json
    else
      return Cloudinary::Utils.sign_request(cloudinary_params, options).to_json
    end
  end

  def cl_image_upload_tag(field, options={})
    html_options = options.delete(:html) || {}
    if options.delete(:multiple)
      html_options[:multiple] = true
      field = "#{ field }[]" unless field.to_s[-2..-1] == "[]"
    end

    tag_options = html_options.merge(:type=>"file", :name=>"file",
      :"data-url"=>cl_upload_url(options),
      :"data-form-data"=>cl_upload_tag_params(options),
      :"data-cloudinary-field"=>field,
      :"data-max-chunk-size"=>options[:chunk_size],
      :"class" => [html_options[:class], "cloudinary-fileupload"].flatten.compact
    ).reject{|k,v| v.blank?}
    tag("input", tag_options)
  end
  alias_method :cl_upload_tag, :cl_image_upload_tag

  def cl_unsigned_image_upload_tag(field, upload_preset, options={})
    cl_image_upload_tag(field, options.merge(:unsigned => true, :upload_preset => upload_preset))
  end
  alias_method :cl_unsigned_upload_tag, :cl_unsigned_image_upload_tag

  def cl_private_download_url(public_id, format, options = {})
    Cloudinary::Utils.private_download_url(public_id, format, options)
  end

  # Helper method that uses the deprecated ZIP download API.
  # Replaced by cl_download_zip_url that uses the more advanced and robust archive generation and download API
  # @deprecated
  def cl_zip_download_url(tag, options = {})
    Cloudinary::Utils.zip_download_url(tag, options)
  end

  # @see {Cloudinary::Utils.download_archive_url}
  def cl_download_archive_url(options = {})
    Cloudinary::Utils.download_archive_url(options)
  end

  # @see {Cloudinary::Utils.download_zip_url}
  def cl_download_zip_url(options = {})
    Cloudinary::Utils.download_zip_url(options)
  end

  def cl_signed_download_url(public_id, options = {})
    Cloudinary::Utils.signed_download_url(public_id, options)
  end

  def self.included(base)
    ActionView::Helpers::FormBuilder.send(:include, Cloudinary::FormBuilder)
    base.class_eval do
      if !method_defined?(:image_tag)
        include ActionView::Helpers::AssetTagHelper
      end
      alias_method :image_tag_without_cloudinary, :image_tag unless public_method_defined? :image_tag_without_cloudinary
      alias_method :image_path_without_cloudinary, :image_path unless public_method_defined? :image_path_without_cloudinary
      if Cloudinary.config.enhance_image_tag
        alias_method :image_tag, :image_tag_with_cloudinary
        alias_method :image_path, :image_path_with_cloudinary
      end
    end
  end

  private

  def cloudinary_url_internal(source, options = {})
    options[:ssl_detected] = request.ssl? if defined?(request) && request && request.respond_to?(:ssl?)
    if defined?(CarrierWave::Uploader::Base) && source.is_a?(CarrierWave::Uploader::Base)
      if source.version_name.present?
        options[:transformation] = Cloudinary::Utils.build_array(source.transformation) + Cloudinary::Utils.build_array(options[:transformation])
      end
      options.reverse_merge!(
        :resource_type => Cloudinary::Utils.resource_type_for_format(source.filename || source.format),
        :type => source.storage_type,
        :format => source.format)
      source = source.full_public_id
    end
    Cloudinary::Utils.cloudinary_url(source, options)
  end

  def build_callback_url(options)
    callback_path = options.delete(:callback_cors) || Cloudinary.config.callback_cors || "/cloudinary_cors.html"
    if callback_path.match(/^https?:\/\//)
      callback_path
    else
      callback_url = request.scheme + "://"
      callback_url << request.host
      if request.scheme == "https" && request.port != 443 ||
        request.scheme == "http" && request.port != 80
        callback_url << ":#{request.port}"
      end
      callback_url << callback_path
    end
  end
end

module Cloudinary::FormBuilder
  def cl_image_upload(method, options={})
    @template.cl_image_upload(@object_name, method, objectify_options(options))
  end
  alias_method :cl_upload, :cl_image_upload
  def cl_unsigned_image_upload(method, upload_preset, options={})
    @template.cl_unsigned_image_upload(@object_name, method, upload_preset, objectify_options(options))
  end
  alias_method :cl_unsigned_upload, :cl_unsigned_image_upload
end

if defined? ActionView::Helpers::AssetUrlHelper
  module ActionView::Helpers::AssetUrlHelper
    alias :original_path_to_asset :path_to_asset

    def path_to_asset(source, options={})
      options ||= {}
      if Cloudinary.config.enhance_image_tag && options[:type] == :image
        source = Cloudinary::Utils.cloudinary_url(source, options.merge(:type=>:asset))
      end
      original_path_to_asset(source, options)
    end
  end
end

if defined?(::Rails::VERSION::MAJOR) && ::Rails::VERSION::MAJOR == 2
  ActionView::Base.send :include, ActionView::Helpers::AssetTagHelper
  ActionView::Base.send :include, CloudinaryHelper
end

begin
  require 'sass-rails'
  if defined?(Sass::Rails::Resolver)
    class Sass::Rails::Resolver
      alias :original_image_path :image_path
      def image_path(img)
        if Cloudinary.config.enhance_image_tag
          original_image_path(Cloudinary::Utils.cloudinary_url(img, :type=>:asset))
        else
          original_image_path(img)
        end
      end
    end
  end
rescue LoadError
  # no sass rails support. Ignore.
end

begin
  require 'sass'
  require 'sass/script/functions'
  module Sass::Script::Functions
    def cloudinary_url(public_id, sass_options={})
      options = {}
      sass_options.each{|k, v| options[k.to_sym] = v.value}
      url = Cloudinary::Utils.cloudinary_url(public_id.value, {:type=>:asset}.merge(options))
      Sass::Script::String.new("url(#{url})")
    end
    declare :cloudinary_url, [:string], :var_kwargs => true
  end
rescue LoadError
  # no sass support. Ignore.
end

begin
  require 'sassc'
  require 'sassc/script/functions'
  module SassC::Script::Functions
    # Helper method for generating cloudinary_url in scss files.
    #
    # As opposed to sass(deprecated), optional named arguments are not supported, use hash map instead.
    #
    # Example:
    #   Sass: cloudinary-url("sample", $quality: "auto", $fetch_format: "auto");
    #  becomes
    #   SassC: cloudinary-url("sample", ("quality": "auto", "fetch_format": "auto"));
    #
    # @param [::SassC::Script::Value::String] public_id The public ID of the resource
    # @param [::SassC::Script::Value::Map] sass_options Additional options
    #
    # @return [::SassC::Script::Value::String]
    def cloudinary_url(public_id, sass_options = {})
      options = {}
      sass_options.to_h.each { |k, v| options[k.value.to_sym] = v.value }
      url = Cloudinary::Utils.cloudinary_url(public_id.value, {:type => :asset}.merge(options))
      ::SassC::Script::Value::String.new("url(#{url})")
    end
  end
rescue LoadError
  # no sassc support. Ignore.
end
