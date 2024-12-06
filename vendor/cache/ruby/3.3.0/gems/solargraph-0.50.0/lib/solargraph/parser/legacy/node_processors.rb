# frozen_string_literal: true

require 'solargraph/parser/node_processor'

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        autoload :BeginNode,     'solargraph/parser/legacy/node_processors/begin_node'
        autoload :DefNode,       'solargraph/parser/legacy/node_processors/def_node'
        autoload :DefsNode,      'solargraph/parser/legacy/node_processors/defs_node'
        autoload :SendNode,      'solargraph/parser/legacy/node_processors/send_node'
        autoload :NamespaceNode, 'solargraph/parser/legacy/node_processors/namespace_node'
        autoload :SclassNode,    'solargraph/parser/legacy/node_processors/sclass_node'
        autoload :ModuleNode,    'solargraph/parser/legacy/node_processors/module_node'
        autoload :IvasgnNode,    'solargraph/parser/legacy/node_processors/ivasgn_node'
        autoload :CvasgnNode,    'solargraph/parser/legacy/node_processors/cvasgn_node'
        autoload :LvasgnNode,    'solargraph/parser/legacy/node_processors/lvasgn_node'
        autoload :GvasgnNode,    'solargraph/parser/legacy/node_processors/gvasgn_node'
        autoload :CasgnNode,     'solargraph/parser/legacy/node_processors/casgn_node'
        autoload :AliasNode,     'solargraph/parser/legacy/node_processors/alias_node'
        autoload :ArgsNode,      'solargraph/parser/legacy/node_processors/args_node'
        autoload :BlockNode,     'solargraph/parser/legacy/node_processors/block_node'
        autoload :OrasgnNode,    'solargraph/parser/legacy/node_processors/orasgn_node'
        autoload :SymNode,       'solargraph/parser/legacy/node_processors/sym_node'
        autoload :ResbodyNode,   'solargraph/parser/legacy/node_processors/resbody_node'
      end
    end

    module NodeProcessor
      register :source,  Legacy::NodeProcessors::BeginNode
      register :begin,   Legacy::NodeProcessors::BeginNode
      register :kwbegin, Legacy::NodeProcessors::BeginNode
      register :rescue,  Legacy::NodeProcessors::BeginNode
      register :resbody, Legacy::NodeProcessors::ResbodyNode
      register :def,     Legacy::NodeProcessors::DefNode
      register :defs,    Legacy::NodeProcessors::DefsNode
      register :send,    Legacy::NodeProcessors::SendNode
      register :class,   Legacy::NodeProcessors::NamespaceNode
      register :module,  Legacy::NodeProcessors::NamespaceNode
      register :sclass,  Legacy::NodeProcessors::SclassNode
      register :ivasgn,  Legacy::NodeProcessors::IvasgnNode
      register :cvasgn,  Legacy::NodeProcessors::CvasgnNode
      register :lvasgn,  Legacy::NodeProcessors::LvasgnNode
      register :gvasgn,  Legacy::NodeProcessors::GvasgnNode
      register :casgn,   Legacy::NodeProcessors::CasgnNode
      register :alias,   Legacy::NodeProcessors::AliasNode
      register :args,    Legacy::NodeProcessors::ArgsNode
      register :block,   Legacy::NodeProcessors::BlockNode
      register :or_asgn, Legacy::NodeProcessors::OrasgnNode
      register :sym,     Legacy::NodeProcessors::SymNode
    end
  end
end
