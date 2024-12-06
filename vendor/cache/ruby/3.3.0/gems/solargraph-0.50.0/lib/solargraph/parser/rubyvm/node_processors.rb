# frozen_string_literal: true

require 'solargraph/parser/node_processor'

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        autoload :ScopeNode,     'solargraph/parser/rubyvm/node_processors/scope_node'
        autoload :BeginNode,     'solargraph/parser/rubyvm/node_processors/begin_node'
        autoload :DefNode,       'solargraph/parser/rubyvm/node_processors/def_node'
        autoload :DefsNode,      'solargraph/parser/rubyvm/node_processors/defs_node'
        autoload :SendNode,      'solargraph/parser/rubyvm/node_processors/send_node'
        autoload :NamespaceNode, 'solargraph/parser/rubyvm/node_processors/namespace_node'
        autoload :SclassNode,    'solargraph/parser/rubyvm/node_processors/sclass_node'
        autoload :ModuleNode,    'solargraph/parser/rubyvm/node_processors/module_node'
        autoload :IvasgnNode,    'solargraph/parser/rubyvm/node_processors/ivasgn_node'
        autoload :CvasgnNode,    'solargraph/parser/rubyvm/node_processors/cvasgn_node'
        autoload :LvasgnNode,    'solargraph/parser/rubyvm/node_processors/lvasgn_node'
        autoload :GvasgnNode,    'solargraph/parser/rubyvm/node_processors/gvasgn_node'
        autoload :CasgnNode,     'solargraph/parser/rubyvm/node_processors/casgn_node'
        autoload :AliasNode,     'solargraph/parser/rubyvm/node_processors/alias_node'
        autoload :ArgsNode,      'solargraph/parser/rubyvm/node_processors/args_node'
        autoload :OptArgNode,    'solargraph/parser/rubyvm/node_processors/opt_arg_node'
        autoload :KwArgNode,     'solargraph/parser/rubyvm/node_processors/kw_arg_node'
        autoload :BlockNode,     'solargraph/parser/rubyvm/node_processors/block_node'
        autoload :OrasgnNode,    'solargraph/parser/rubyvm/node_processors/orasgn_node'
        autoload :SymNode,       'solargraph/parser/rubyvm/node_processors/sym_node'
        autoload :LitNode,       'solargraph/parser/rubyvm/node_processors/lit_node'
        autoload :ResbodyNode,   'solargraph/parser/rubyvm/node_processors/resbody_node'
      end
    end

    module NodeProcessor
      register :SCOPE,      Rubyvm::NodeProcessors::ScopeNode
      register :RESBODY,    Rubyvm::NodeProcessors::ResbodyNode
      register :DEFN,       Rubyvm::NodeProcessors::DefNode
      register :DEFS,       Rubyvm::NodeProcessors::DefsNode
      register :CALL,       Rubyvm::NodeProcessors::SendNode
      register :FCALL,      Rubyvm::NodeProcessors::SendNode
      register :VCALL,      Rubyvm::NodeProcessors::SendNode
      register :CLASS,      Rubyvm::NodeProcessors::NamespaceNode
      register :MODULE,     Rubyvm::NodeProcessors::NamespaceNode
      register :SCLASS,     Rubyvm::NodeProcessors::SclassNode
      register :IASGN,      Rubyvm::NodeProcessors::IvasgnNode
      register :CVASGN,     Rubyvm::NodeProcessors::CvasgnNode
      register :LASGN,      Rubyvm::NodeProcessors::LvasgnNode
      register :DASGN,      Rubyvm::NodeProcessors::LvasgnNode
      register :DASGN_CURR, Rubyvm::NodeProcessors::LvasgnNode
      register :GASGN,      Rubyvm::NodeProcessors::GvasgnNode
      register :CDECL,      Rubyvm::NodeProcessors::CasgnNode
      register :ALIAS,      Rubyvm::NodeProcessors::AliasNode
      register :ARGS,       Rubyvm::NodeProcessors::ArgsNode
      register :OPT_ARG,    Rubyvm::NodeProcessors::OptArgNode
      register :KW_ARG,     Rubyvm::NodeProcessors::KwArgNode
      register :ITER,       Rubyvm::NodeProcessors::BlockNode
      register :LAMBDA,     Rubyvm::NodeProcessors::BlockNode
      register :FOR,        Rubyvm::NodeProcessors::BlockNode
      register :OP_ASGN_OR, Rubyvm::NodeProcessors::OrasgnNode
      register :LIT,        Rubyvm::NodeProcessors::LitNode
    end
  end
end
