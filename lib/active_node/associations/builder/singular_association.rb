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
  end
end
