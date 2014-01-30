require 'active_node/associations'

module ActiveNode::Associations::Builder
  class CollectionAssociation < Association #:nodoc:
    def define_readers
      super

      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name.to_s.singularize}_ids
          association(:#{name}).ids_reader
        end

        def #{name.to_s.singularize}_rels
          association(:#{name}).rels_reader
        end
      CODE
    end

    def define_writers
      super

      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name.to_s.singularize}_ids=(ids)
          association(:#{name}).ids_writer(ids)
        end

        def #{name.to_s.singularize}_rels=(ids)
          association(:#{name}).rels_writer(ids)
        end
      CODE
    end
  end
end
