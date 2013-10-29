module ActiveNode
  module Associations
    class SingularAssociation < Association #:nodoc:
      def load_target
        super.try :first
      end

      def target_each
        yield target
      end

      def ids_reader
        [id_reader].compact
      end

      def id_reader
        target.try :id
      end

      def id_writer(id)
        writer(klass.find(id.to_i))
      end
    end
  end
end
