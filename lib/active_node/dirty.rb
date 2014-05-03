module ActiveNode
  module Dirty
    extend ActiveSupport::Concern
    include ActiveModel::Dirty

    module ClassMethods
      def attribute!(name, options={})
        super(name, options)
        define_method("#{name}=") do |value|
          send("#{name}_will_change!") unless value == read_attribute(name)
          super(value)
        end
      end
    end

    def initialize(attributes = nil, options = {})
      super(attributes, options)
      (@changed_attributes || {}).clear
    end

    def save(*)
      @previously_changed = changes
      @changed_attributes.clear
    end
  end
end