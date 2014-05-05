module ActiveNode
  module QueryMethods
    def order(*args)
      self
    end

    def offset(value)
      self
    end

    def reverse_order
      self
    end

    #TODO temporary stubbing
    def offset_value
      0
    end

    def order_values
      []
    end

    def limit_value
      nil
    end
  end
end