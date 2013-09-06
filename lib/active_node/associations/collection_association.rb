module ActiveNode
  module Associations
    # = Active Record Association Collection
    #
    # CollectionAssociation is an abstract class that provides common stuff to
    # ease the implementation of association proxies that represent
    # collections. See the class hierarchy in AssociationProxy.
    #
    #   CollectionAssociation:
    #     HasAndBelongsToManyAssociation => has_and_belongs_to_many
    #     HasManyAssociation => has_many
    #       HasManyThroughAssociation + ThroughAssociation => has_many :through
    #
    # CollectionAssociation class provides common methods to the collections
    # defined by +has_and_belongs_to_many+, +has_many+ or +has_many+ with
    # +:through association+ option.
    #
    # You need to be careful with assumptions regarding the target: The proxy
    # does not fetch records from the database until it needs them, but new
    # ones created with +build+ are added to the target. So, the target may be
    # non-empty and still lack children waiting to be read from the database.
    # If you look directly to the database you cannot assume that's the entire
    # collection because new records may have been added to the target, etc.
    #
    # If you need to work on all current children, new and existing records,
    # +load_target+ and the +loaded+ flag are your friends.
    class CollectionAssociation < Association #:nodoc:

      # Implements the reader method, e.g. foo.items for Foo.has_many :items
      def reader(force_reload = false)
        @target ||= load_target
      end

      # Implements the writer method, e.g. foo.items= for Foo.has_many :items
      def writer(records)
        @dirty = true
        @target = records
      end

      # Implements the ids reader method, e.g. foo.item_ids for Foo.has_many :items
      def ids_reader
        reader.map(&:id)
      end

      # Implements the ids writer method, e.g. foo.item_ids= for Foo.has_many :items
      def ids_writer(ids)
        writer klass.find(ids.reject(&:blank?).map!(&:to_i))
      end

      def load_target
        owner.send(reflection.direction, reflection.type, reflection.klass)
      end

      def save
        return unless @dirty
        #delete all relations missing in new target
        owner.node.rels(reflection.type).send(reflection.direction).each do |rel|
          rel.del unless ids_reader.include? rel.other_node(owner.node).neo_id.to_i
        end
        original_target = owner.node.send(reflection.direction, reflection.type)
        original_target_ids = original_target.map(&:neo_id).map(&:to_i)
        #add relations missing in old target
        @target.each { |n| original_target << n.node unless original_target_ids.include? n.id }
      end

      def reset
        super
        @target = owner.new_record? ? [] : nil
        @dirty = false
      end
    end
  end
end
