module Solargraph
  module Parser
    module Legacy
      autoload :FlawedBuilder, 'solargraph/parser/legacy/flawed_builder'
      autoload :ClassMethods, 'solargraph/parser/legacy/class_methods'
      autoload :NodeMethods, 'solargraph/parser/legacy/node_methods'
      autoload :NodeChainer, 'solargraph/parser/legacy/node_chainer'
    end
  end
end

require 'solargraph/parser/legacy/node_processors'
