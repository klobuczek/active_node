module ActiveNode
  module Persistence
    extend ActiveSupport::Concern

    module ClassMethods
      def find id
        new_instance Neography::Node.load(id)
      end

      def all
        Neography::Node.find(:node_auto_index, :type, type).map { |node| new_instance(node) }
      end

      def create attrs={}
        new(attrs).save
      end

      def type
        name.underscore
      end

      def wrap node
        node.is_a?(Enumerable) ?
            node.map { |n| wrap(n) } :
            node.is_a?(Neography::Node) && (active_node_class(node.type.camelize)).try(:new, node) || node
      end

      def active_node_class(class_name)
        klass = Module.const_get(class_name) rescue nil
        klass && klass < ActiveNode::Base && klass
      end

      private
      def new_instance node
        node && new(node)
      end

      def class_exists? class_name
        Module.const_get(class_name) rescue false
      end
    end

    attr_reader :node
    protected :node

    delegate :neo_id, to: :node, allow_nil: true
    alias :id :neo_id
    alias :to_param :id
    alias :persisted? :id
    alias :[] :send

    def initialize hash={}
      @node, hash = hash, hash.send(:table) if hash.is_a? Neography::Node
      super hash
    end

    def new_record?
      !id
    end

    def save(*)
      create_or_update
    end

    def incoming(types=nil)
      node && self.class.wrap(node.incoming types)
    end

    def outgoing(types=nil)
      node && self.class.wrap(node.outgoing types)
    end

    private
    def nullify_blanks! attrs
      attrs.each { |k, v| attrs[k]=nil if attrs[k].blank? }
    end

    def create_or_update
      write; true
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