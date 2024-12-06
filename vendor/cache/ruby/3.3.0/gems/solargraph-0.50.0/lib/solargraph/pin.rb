# frozen_string_literal: true

require 'yard'

module Solargraph
  # The namespace for pins used in maps.
  #
  module Pin
    autoload :Common,           'solargraph/pin/common'
    autoload :Conversions,      'solargraph/pin/conversions'
    autoload :Base,             'solargraph/pin/base'
    autoload :Method,           'solargraph/pin/method'
    autoload :Signature,        'solargraph/pin/signature'
    autoload :MethodAlias,      'solargraph/pin/method_alias'
    autoload :BaseVariable,     'solargraph/pin/base_variable'
    autoload :InstanceVariable, 'solargraph/pin/instance_variable'
    autoload :ClassVariable,    'solargraph/pin/class_variable'
    autoload :LocalVariable,    'solargraph/pin/local_variable'
    autoload :GlobalVariable,   'solargraph/pin/global_variable'
    autoload :Constant,         'solargraph/pin/constant'
    autoload :Symbol,           'solargraph/pin/symbol'
    autoload :Closure,          'solargraph/pin/closure'
    autoload :Namespace,        'solargraph/pin/namespace'
    autoload :Keyword,          'solargraph/pin/keyword'
    autoload :Parameter,        'solargraph/pin/parameter'
    autoload :Reference,        'solargraph/pin/reference'
    autoload :Documenting,      'solargraph/pin/documenting'
    autoload :Block,            'solargraph/pin/block'
    autoload :Localized,        'solargraph/pin/localized'
    autoload :ProxyType,        'solargraph/pin/proxy_type'
    autoload :DuckMethod,       'solargraph/pin/duck_method'
    autoload :Singleton,        'solargraph/pin/singleton'
    autoload :KeywordParam,     'solargraph/pin/keyword_param'
    autoload :Search,           'solargraph/pin/search'

    ROOT_PIN = Pin::Namespace.new(type: :class, name: '', closure: nil)
  end
end
