# frozen_string_literal: true

class Capybara::RackTest::Form < Capybara::RackTest::Node
  # This only needs to inherit from Rack::Test::UploadedFile because Rack::Test checks for
  # the class specifically when determining whether to construct the request as multipart.
  # That check should be based solely on the form element's 'enctype' attribute value,
  # which should probably be provided to Rack::Test in its non-GET request methods.
  class NilUploadedFile < Rack::Test::UploadedFile
    def initialize # rubocop:disable Lint/MissingSuper
      @empty_file = Tempfile.new('nil_uploaded_file')
      @empty_file.close
    end

    def original_filename; ''; end
    def content_type; 'application/octet-stream'; end
    def path; @empty_file.path; end
    def size; 0; end
    def read; ''; end
  end

  def params(button)
    form_element_types = %i[input select textarea button]
    form_elements_xpath = XPath.generate do |xp|
      xpath = xp.descendant(*form_element_types).where(!xp.attr(:form))
      xpath += xp.anywhere(*form_element_types).where(xp.attr(:form) == native[:id]) if native[:id]
      xpath.where(!xp.attr(:disabled))
    end.to_s

    form_elements = native.xpath(form_elements_xpath).reject { |el| submitter?(el) && (el != button.native) }

    form_elements.each_with_object(make_params) do |field, params|
      case field.name
      when 'input', 'button' then add_input_param(field, params)
      when 'select' then add_select_param(field, params)
      when 'textarea' then add_textarea_param(field, params)
      end
    end.to_params_hash
  end

  def submit(button)
    action = button&.[]('formaction') || native['action']
    method = button&.[]('formmethod') || request_method
    driver.submit(method, action.to_s, params(button))
  end

  def multipart?
    self[:enctype] == 'multipart/form-data'
  end

private

  class ParamsHash < Hash
    def to_params_hash
      self
    end
  end

  def request_method
    /post/i.match?(self[:method] || '') ? :post : :get
  end

  def merge_param!(params, key, value)
    key = key.to_s
    if Rack::Utils.respond_to?(:default_query_parser)
      Rack::Utils.default_query_parser.normalize_params(params, key, value, Rack::Utils.param_depth_limit)
    else
      Rack::Utils.normalize_params(params, key, value)
    end
  end

  def make_params
    if Rack::Utils.respond_to?(:default_query_parser)
      Rack::Utils.default_query_parser.make_params
    else
      ParamsHash.new
    end
  end

  def add_input_param(field, params)
    name, value = field['name'].to_s, field['value'].to_s
    return if name.empty?

    value = case field['type']
    when 'radio', 'checkbox'
      return unless field['checked']

      Capybara::RackTest::Node.new(driver, field).value.to_s
    when 'file'
      if multipart?
        file_to_upload(value)
      else
        File.basename(value)
      end
    else
      value
    end
    merge_param!(params, name, value)
  end

  def file_to_upload(filename)
    if filename.empty?
      NilUploadedFile.new
    else
      mime_info = MiniMime.lookup_by_filename(filename)
      Rack::Test::UploadedFile.new(filename, mime_info&.content_type&.to_s)
    end
  end

  def add_select_param(field, params)
    if field.has_attribute?('multiple')
      field.xpath('.//option[@selected]').each do |option|
        merge_param!(params, field['name'], (option['value'] || option.text).to_s)
      end
    else
      option = field.xpath('.//option[@selected]').first || field.xpath('.//option').first
      merge_param!(params, field['name'], (option['value'] || option.text).to_s) if option
    end
  end

  def add_textarea_param(field, params)
    merge_param!(params, field['name'], field['_capybara_raw_value'].to_s.gsub(/\n/, "\r\n"))
  end

  def submitter?(el)
    (%w[submit image].include? el['type']) || (el.name == 'button')
  end
end
