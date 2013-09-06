require 'active_attr'
require 'active_node/errors'

module ActiveNode
  class Base
    include ActiveAttr::Model
    include Persistence
    include Validations
    include Callbacks
    include Associations
    include Reflection
    include Core
  end
end