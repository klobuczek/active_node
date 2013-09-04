require 'active_attr'

module ActiveNode
  class Base
    include ActiveAttr::Model
    include Persistence
    include Validations
    include Callbacks
  end
end