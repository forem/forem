module Responsive
  # Calculate breakpoints for the given configuration
  # @private
  def generate_breakpoints(srcset)
    return srcset[:breakpoints] if srcset[:breakpoints].is_a? Array
    min_width, max_width, max_images = [:min_width, :max_width, :max_images].map {|k| srcset[k]}
    unless [min_width, max_width, max_images].all? {|a| a.is_a? Numeric}
      throw 'Either (min_width, max_width, max_images) or breakpoints must be provided to the image srcset attribute'
    end
    if min_width > max_width
      throw 'min_width must be less than max_width'
    end

    if max_images <= 0
      throw 'max_images must be a positive integer'
    elsif max_images === 1
      min_width = max_width
    end
    step_size = ((max_width - min_width).to_f / [max_images - 1, 1].max).ceil
    current = min_width
    breakpoints = []
    while current < max_width do
      breakpoints.push(current)
      current += step_size
    end
    breakpoints.push(max_width)
  end

  # Generate the srcset and sizes attributes
  # @private
  def generate_image_responsive_attributes(public_id, attributes = {}, srcset_data = {}, options = {})
    # Create both srcset and sizes here to avoid fetching breakpoints twice

    responsive_attributes = {}
    generate_srcset = !attributes[:srcset]

    if srcset_data.empty?
      return responsive_attributes
    elsif srcset_data.is_a? String
      responsive_attributes[:srcset] = srcset_data
      return responsive_attributes
    end

    generate_sizes = !attributes[:sizes] && srcset_data[:sizes]

    if generate_srcset || generate_sizes
      breakpoints = get_or_generate_breakpoints(public_id, srcset_data, options)

      if generate_srcset
        transformation = srcset_data[:transformation]
        srcset_attr = generate_srcset_attribute(public_id, breakpoints, transformation, options)
        responsive_attributes[:srcset] = srcset_attr unless srcset_attr.empty?
      end

      if generate_sizes
        sizes_attr = generate_sizes_attribute(breakpoints)
        responsive_attributes[:sizes] = sizes_attr unless sizes_attr.empty?
      end
    end

    responsive_attributes
  end

  # If cache is enabled, get the breakpoints from the cache. If the values were not found in the cache,
  # or cache is not enabled, generate the values.
  # @private
  def get_or_generate_breakpoints(public_id, srcset, options)
    if srcset[:use_cache]
      Cloudinary::Cache.get(public_id, options) || []
    else
      generate_breakpoints(srcset)
    end
  end

  # Generate a resource URL scaled to the given width
  # @private
  def generate_scaled_url(public_id, width, transformation={}, options={})
    config_params = Cloudinary::Utils.extract_config_params(options)
    transformation ||= options
    config_params[:raw_transformation] = Cloudinary::Utils.generate_transformation_string(
        [transformation.clone, {:crop => 'scale', :width => width}].reject(&:blank?))
    config_params.delete :width
    config_params.delete :height
    Cloudinary::Utils.cloudinary_url public_id, config_params
  end

  # Generate srcset attribute value of the HTML img tag
  # @private
  def generate_srcset_attribute(public_id, breakpoints, transformation={}, options={})
    options = options.clone
    Cloudinary::Utils.patch_fetch_format(options)
    breakpoints.map{|width| "#{generate_scaled_url(public_id, width, transformation, options)} #{width}w"}.join(', ').html_safe
  end

  # Generate media attribute value of the HTML img tag
  # @private
  def generate_media_attribute(options)
    options ||= {}
    [:min_width, :max_width]
      .select {|name| options[name]}
      .map {|name| "(#{name.to_s.tr('_', '-')}: #{options[name]}px)"}
      .join(' and ').html_safe
  end


  # Generate the sizes attribute
  # @private
  def generate_sizes_attribute(breakpoints)
    breakpoints.map{|width| "(max-width: #{width}px) #{width}px"}.join(', ')
  end
end