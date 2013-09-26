require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/module/remove_method'

module ActiveNode
  module Associations # :nodoc:
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern

    autoload :Association,           'active_node/associations/association'
    autoload :SingularAssociation, 'active_node/associations/singular_association'
    autoload :CollectionAssociation, 'active_node/associations/collection_association'
    autoload :HasOneAssociation,              'active_node/associations/has_one_association'
    autoload :HasManyAssociation,              'active_node/associations/has_many_association'

    module Builder #:nodoc:
      autoload :Association,           'active_node/associations/builder/association'
      autoload :SingularAssociation, 'active_node/associations/builder/singular_association'
      autoload :CollectionAssociation, 'active_node/associations/builder/collection_association'

      autoload :HasOne,             'active_node/associations/builder/has_one'
      autoload :HasMany,             'active_node/associations/builder/has_many'
    end


    # Clears out the association cache.
    def clear_association_cache #:nodoc:
      @association_cache.clear if persisted?
    end

    # :nodoc:
    attr_reader :association_cache

    # Returns the association instance for the given name, instantiating it if it doesn't already exist
    def association(name) #:nodoc:
      association = association_instance_get(name)

      if association.nil?
        reflection  = self.class.reflect_on_association(name)
        association = reflection.association_class.new(self, reflection)
        association_instance_set(name, association)
      end

      association
    end

    private
      # Returns the specified association instance if it responds to :loaded?, nil otherwise.
      def association_instance_get(name)
        @association_cache[name.to_sym]
      end

      # Set the specified association instance.
      def association_instance_set(name, association)
        @association_cache[name] = association
      end

    module ClassMethods
      def has_many(name, options = {})
        Builder::HasMany.build(self, name, options)
      end

      def has_one(name, options = {})
        Builder::HasOne.build(self, name, options)
      end
    end
  end
end
