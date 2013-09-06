module ActiveNode::Associations::Builder
  class HasMany < CollectionAssociation #:nodoc:
    def macro
      :has_many
    end

    def valid_options
      super + [:direction, :type]
    end
  end
end
