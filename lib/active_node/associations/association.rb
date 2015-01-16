require 'active_support/core_ext/array/wrap'

module ActiveNode
  module Associations
    # = Active Record Associations
    #
    # This is the root class of all associations ('+ Foo' signifies an included module Foo):
    #
    #   Association
    #     SingularAssociation
    #       HasOneAssociation
    #         HasOneThroughAssociation + ThroughAssociation
    #       BelongsToAssociation
    #         BelongsToPolymorphicAssociation
    #     CollectionAssociation
    #       HasAndBelongsToManyAssociation
    #       HasManyAssociation
    #         HasManyThroughAssociation + ThroughAssociation
    class Association #:nodoc:
      attr_reader :owner, :target, :rel_target, :reflection

      delegate :options, :to => :reflection

      def initialize(owner, reflection)
        @owner, @reflection = owner, reflection

        reset
      end

      # Resets the \loaded flag to +false+ and sets the \target to +nil+.
      def reset
        @loaded = false
        @target = nil
        @stale_state = nil
      end

      # Returns the class of the target. belongs_to polymorphic overrides this to look at the
      # polymorphic_type field on the owner.
      def klass
        reflection.klass
      end

      def rel(*associations)
        @loaded = true
        owner.includes!(reflection.name => associations)
      end

      # Implements the writer method, e.g. foo.items= for Foo.has_many :items
      def writer(records)
        validate_type(records)
        @dirty = true
        @rel_target = nil
        @target = records
      end

      def validate_type(records)
        unless records.all? { |r| r.is_a?(reflection.klass) }
          raise ArgumentError, "#{reflection.name} can only accept object(s) of class #{reflection.klass}"
        end
      end

      alias :super_writer :writer

      # Implements the ids writer method, e.g. foo.item_ids= for Foo.has_many :items
      def ids_writer(ids)
        @rel_target = nil
        super_writer klass.find(ids.reject(&:blank?).map!(&:to_i))
      end

      def reader(*args)
        @target ||= rels_reader(*args).map &:other
      end

      # Implements the ids reader method, e.g. foo.item_ids for Foo.has_many :items
      def ids_reader
        reader
        @target.map(&:id)
      end


      def rels_reader(*args)
        rel(*args) unless @loaded
        @rel_target ||= []
      end

      def rels_writer(rels)
        @dirty = true
        rels_loader(rels)
      end

      def rels_loader(rels)
        @target = nil
        @rel_target = rels
        @loaded = true
      end

      def save(fresh=false)
        #return unless @dirty
        #delete all relations missing in new target
        original_rels = fresh ? [] : owner.class.includes(reflection.name).build(owner.id).first.association(reflection.name).rels_reader
        original_rels.each do |r|
          unless ids_reader.include? r.other.id
            Neo.db.delete_relationship(r.id)
            original_rels.delete(r)
          end
        end

        #add relations missing in old target
        #if no rel_target proceed as before + set rel_target from db
        #if rel_target exists update persisted records and insert new records
        if @rel_target
          @rel_target.each { |r| r.save(self) }
        else
          @target.map do |n|
            original_rels.detect { |r| r.other.id == n.id }.tap { |o_r| o_r.try :other=, n } ||
                ActiveNode::Relationship.create!(n, self)
          end
        end
      end
    end
  end
end
