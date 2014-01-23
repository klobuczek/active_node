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
      attr_reader :owner, :target, :reflection

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

      def load_target
        owner.send(reflection.direction, reflection.type, reflection.klass)
      end

      # Implements the reader method, e.g. foo.items for Foo.has_many :items
      def reader(force_reload = false)
        @target ||= load_target
      end

      # Implements the writer method, e.g. foo.items= for Foo.has_many :items
      def writer(records)
        @dirty = true
        @target = records
      end

      def save
        return unless @dirty
        #delete all relations missing in new target
        node = Neography::Node.load(owner.id)
        node.rels(reflection.type).send(reflection.direction).each do |rel|
          rel.del unless ids_reader.include? rel.other_node(node).neo_id.to_i
        end
        original_target = node.send(reflection.direction, reflection.type)
        original_target_ids = original_target.map(&:neo_id).map(&:to_i)
        #add relations missing in old target
        target_each { |n| original_target << n.id unless original_target_ids.include? n.id }
      end
    end
  end
end
