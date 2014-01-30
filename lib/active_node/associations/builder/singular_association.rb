module ActiveNode::Associations::Builder
  class SingularAssociation < Association #:nodoc:
    def define_constructors
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def build_#{name}(*args, &block)
          association(:#{name}).build(*args, &block)
        end

        def create_#{name}(*args, &block)
          association(:#{name}).create(*args, &block)
        end

        def create_#{name}!(*args, &block)
          association(:#{name}).create!(*args, &block)
        end
      CODE
    end

    def define_readers
      super

      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_id
          association(:#{name}).id_reader
        end

        def #{name}_rel
          association(:#{name}).rel_reader
        end
      CODE
    end

    def define_writers
      super

      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_id=(value)
          association(:#{name}).id_writer(value)
        end

        def #{name}_rel=(value)
          association(:#{name}).rel_writer(value)
        end
      CODE
    end
  end
end
