module ActiveNode
  module Persistence
    extend ActiveSupport::Concern

    included do
      attribute :id
    end

    module ClassMethods
      def timestamps
        attribute :created_at, type: String
        attribute :updated_at, type: String
      end

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

      def filterClass(nodes, klass)
        wrap(nodes.select { |node| klass.nil? || node.type == klass.name.underscore }, klass)
      end

      private
      def new_instance node
        new(node) if node.try(:type) == type
      end
    end

    attr_reader :node
    delegate :neo_id, to: :node, allow_nil: true

    def id
      neo_id && neo_id.to_i
    end

    alias :to_param :id
    alias :persisted? :id

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
      related(:incoming, types, klass)
    end

    def outgoing(types=nil, klass=nil)
      related(:outgoing, types, klass)
    end

    private
    def related(direction, types, klass)
      node && self.class.filterClass(node.send(direction, types), klass)
    end

    def destroy_associations include_associations
      rels = node.rels
      return false unless rels.empty? || include_associations
      rels.each { |rel| rel.del }
      true
    end

    def nullify_blanks! attrs
      attrs.each { |k, v| attrs[k]=nil if v.blank? }
    end

    def create_or_update
      write; true
      association_cache.values.each &:save
    end

    def write
      now = Time.now.utc.iso8601(3)
      try :updated_at=, now
      if @node
        nullify_blanks!(self.attributes).each { |k, v| @node[k]=v }
      else
        try :created_at=, now
        @node = Neography::Node.create nullify_blanks!(self.attributes).merge!(type: self.class.type)
      end
    end
  end
end