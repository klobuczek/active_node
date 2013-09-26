module ActiveNode::Associations::Builder
  class HasOne < SingularAssociation #:nodoc:
    def macro
      :has_one
    end
  end
end
