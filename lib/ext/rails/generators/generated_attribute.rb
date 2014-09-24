module Rails
  module Generators
    class GeneratedAttribute
      def type_class
        type.to_s.camelcase
      end
    end
  end
end
