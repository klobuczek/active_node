module ActiveNode
  module Persistence
    extend ActiveSupport::Concern

    included do
      attribute :id
    end

    module ClassMethods
      def find ids
        ids.is_a?(Enumerable) ? ids.map { |id| find(id) } : new_instance(Neography::Node.load(ids))
      end

      def all
        result = Neography::Node.find(:node_auto_index, :type, type)
        (result.is_a?(Enumerable) ? result : [result]).map { |node| new_instance(node) }.compact
      end

      def type
        name.underscore
      end

      def wrap node, klass=nil
        node.is_a?(Enumerable) ?
            node.map { |n| wrap(n, klass) } :
            node.is_a?(Neography::Node) && (active_node_class(node.type.camelize, klass)).try(:new, node) || node
      end

      def active_node_class(class_name, default_klass=nil)
        klass = Module.const_get(class_name) rescue nil
        klass && klass < ActiveNode::Base && klass || default_klass
      end

      private
      def new_instance node
        node && new(node)
      end
    end

    attr_reader :node
    #protected :node

    delegate :neo_id, to: :node, allow_nil: true
    def id
      neo_id && neo_id.to_i
    end
    alias :to_param :id
    alias :persisted? :id

    alias :[] :send

    def initialize object={}
      hash=object
      @node, hash = object, object.send(:table) if object.is_a? Neography::Node
      super hash
    end

    def new_record?
      !id
    end

    def save(*)
      create_or_update
    end

    alias save! save

    def destroy include_relationships=false
      destroyable = destroy_associations include_relationships
      node.del if destroyable
      @destroyed = destroyable
    end

    def destroy!
      destroy true
    end

    def incoming(types=nil, klass=nil)
      node && self.class.wrap(node.incoming(types), klass)
    end

    def outgoing(types=nil, klass=nil)
      node && self.class.wrap(node.outgoing(types), klass)
    end

    private
    def destroy_associations include_associations
      rels = node.rels
      return false unless rels.empty? || include_associations
      rels.each { |rel| rel.del }
      true
    end

    def nullify_blanks! attrs
      attrs.each { |k, v| attrs[k]=nil if attrs[k].blank? }
    end

    def create_or_update
      write; true
      association_cache.values.each &:save
    end

    def write
      if @node
        nullify_blanks!(attributes).each { |k, v| @node[k]=v }
      else
        @node = Neography::Node.create nullify_blanks!(attributes).merge(type: self.class.type)
      end
    end
  end
end