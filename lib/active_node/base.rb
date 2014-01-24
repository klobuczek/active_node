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

    def self.subclass(klass_name)
      Class.new(super_class=self) { define_singleton_method(:label) { klass_name } }
    end
  end
end