module InlineSvg::TransformPipeline::Transformations
  # Transformations are run in priority order, lowest number first:
  def self.built_in_transformations
    {
      id: { transform: IdAttribute, priority: 1 },
      desc: { transform: Description, priority: 2 },
      title: { transform: Title, priority: 3 },
      aria: { transform: AriaAttributes },
      aria_hidden: { transform: AriaHiddenAttribute },
      class: { transform: ClassAttribute },
      style: { transform: StyleAttribute },
      data: { transform: DataAttributes },
      nocomment: { transform: NoComment },
      preserve_aspect_ratio: { transform: PreserveAspectRatio },
      size: { transform: Size },
      width: { transform: Width },
      height: { transform: Height },
      view_box: { transform: ViewBox },
    }
  end

  def self.custom_transformations
    magnify_priorities(InlineSvg.configuration.custom_transformations)
  end

  def self.magnify_priorities(transforms)
    transforms.inject({}) do |output, (name, definition)|
      priority = definition.fetch(:priority, built_in_transformations.size)

      output[name] = definition.merge( { priority: magnify(priority) } )
      output
    end
  end

  def self.magnify(priority=0)
    (priority + 1) * built_in_transformations.size
  end

  def self.all_transformations
    in_priority_order(built_in_transformations.merge(custom_transformations))
  end

  def self.lookup(transform_params)
    return [] unless transform_params.any? || custom_transformations.any?

    transform_params_with_defaults = params_with_defaults(transform_params)
    all_transformations.map { |name, definition|
      value = transform_params_with_defaults[name]
      definition.fetch(:transform, no_transform).create_with_value(value) if value
    }.compact
  end

  def self.in_priority_order(transforms)
    transforms.sort_by { |_, options| options.fetch(:priority, transforms.size) }
  end

  def self.params_with_defaults(params)
    without_empty_values(all_default_values.merge(params))
  end

  def self.without_empty_values(params)
    params.reject {|key, value| value.nil?}
  end

  def self.all_default_values
    custom_transformations
      .values
      .select {|opt| opt[:default_value] != nil}
      .map {|opt| [opt[:attribute], opt[:default_value]]}
      .inject({}) {|options, attrs| options.merge!(attrs[0] => attrs[1])}
  end

  def self.no_transform
    InlineSvg::TransformPipeline::Transformations::NullTransformation
  end
end

require 'inline_svg/transform_pipeline/transformations/transformation'
require 'inline_svg/transform_pipeline/transformations/no_comment'
require 'inline_svg/transform_pipeline/transformations/class_attribute'
require 'inline_svg/transform_pipeline/transformations/style_attribute'
require 'inline_svg/transform_pipeline/transformations/title'
require 'inline_svg/transform_pipeline/transformations/description'
require 'inline_svg/transform_pipeline/transformations/size'
require 'inline_svg/transform_pipeline/transformations/height'
require 'inline_svg/transform_pipeline/transformations/width'
require 'inline_svg/transform_pipeline/transformations/view_box'
require 'inline_svg/transform_pipeline/transformations/id_attribute'
require 'inline_svg/transform_pipeline/transformations/data_attributes'
require 'inline_svg/transform_pipeline/transformations/preserve_aspect_ratio'
require 'inline_svg/transform_pipeline/transformations/aria_attributes'
require "inline_svg/transform_pipeline/transformations/aria_hidden_attribute"
