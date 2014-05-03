require 'active_attr'
require 'active_node/errors'

module ActiveNode
  class Base
    include ActiveAttr::BasicModel
    include ActiveAttr::Attributes
    include ActiveAttr::MassAssignment
    include ActiveAttr::TypecastedAttributes
    include Dirty
    include Persistence
    include Validations
    include Callbacks
    include Associations
    include Reflection
    include Core

    def self.subclass(klass_name)
      Class.new(super_class=self) { define_singleton_method(:label) { klass_name } }
    end
  end

  ActiveSupport.run_load_hooks(:active_node, Base)
end