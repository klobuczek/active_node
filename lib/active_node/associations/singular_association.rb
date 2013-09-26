module ActiveNode
  module Associations
    class SingularAssociation < Association #:nodoc:
      def load_target
        super.first
      end

      def target_each
        yield target
      end

      def ids_reader
        [target.try(:id)].compact
      end
    end
  end
end
