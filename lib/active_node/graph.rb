module ActiveNode
  module Graph
    extend ActiveSupport::Autoload

    autoload :Builder, 'active_node/graph/builder'
  end
end