module ActiveNode
  module Associations
    class SingularAssociation < Association #:nodoc:
      def reader
        super.try :first
      end

      def id_reader
        ids_reader.try :first
      end

      def id_writer(id)
        ids_writer([id].compact)
      end

      def rel_reader
        rels_reader.try :first
      end

      def rel_writer(rel)
        rels_writer([rel].compact)
      end

      def writer(record)
        super([record].compact)
      end
    end
  end
end
