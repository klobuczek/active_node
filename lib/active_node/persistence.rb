require 'active_support/core_ext/hash/indifferent_access'
require 'neography'

module ActiveNode
  module Persistence
    extend ActiveSupport::Concern
    include Neography::Rest::Helpers

    included do
      extend Neography::Rest::Helpers
      attribute :id
    end

    module ClassMethods
      delegate :all, :first, :where, :limit, :includes, :delete_all, :build, :find, :offset, :count, :order, to: :graph

      def timestamps
        attribute :created_at, type: Time
        attribute :updated_at, type: Time
      end

      def find_by_cypher query, params={}, klass=nil
        wrap(Neo.db.execute_query(query, params)['data'].map(&:first), klass)
      end

      def label
        name
      end

      def wrap node, klass=nil
        node.is_a?(Array) ? new_instances(node, klass) : new_instance(node, klass)
      end

      def wrap_rel rel, node, klass
        create_rel rel, wrap(node, klass)
      end

      def create_rel rel, node
        ActiveNode::Relationship.new node, rel['data'].merge(id: get_id(rel).to_i)
      end

      def active_node_class(class_name, default_klass=nil)
        klass = Module.const_get(class_name) rescue nil
        klass && klass < ActiveNode::Base && klass || default_klass
      end

      def graph
        ActiveNode::Graph.new(self)
      end

      private
      def new_instance node, klass=nil
        (klass || find_suitable_class(Neo.db.get_node_labels(node))).try(:new, data(node), :declared?)
      end

      def data hash
        hash['data'].merge(id: get_id(hash).to_i)
      end

      def new_instances nodes, klass=nil
        nodes.map { |node| new_instance(node, klass) }.compact
      end

      def find_suitable_class labels
        labels.include?(label) ? self : labels.map { |l| active_node_class(l) }.compact.first
      end
    end

    def [](attr)
      declared?(attr) ? send(attr) : @hash[attr]
    end

    def []=(attr, value)
      if declared? attr
        write_attr attr, value
      else
        @hash[attr]=value
      end
    end

    def neo_id
      id
    end

    def to_param
      id.to_s if persisted?
    end

    def persisted?
      id.present? && !destroyed?
    end

    def initialize hash={}, split_by=:respond_to_writer?
      super(split_hash hash, :select, split_by)
      @hash=(split_hash(hash, :reject, split_by) || {}).with_indifferent_access
    end

    def new_record?
      !id
    end

    def save(*)
      create_or_update
      super
    end

    alias save! save

    def destroy include_relationships=false
      destroyable = destroy_associations include_relationships
      Neo.db.delete_node(id) if destroyable
      @destroyed = destroyable
    end

    def destroyed?
      @destroyed
    end

    def destroy!
      destroy true
    end

    def incoming(type=nil, klass=nil)
      related(:incoming, type, klass)
    end

    def outgoing(type=nil, klass=nil)
      related(:outgoing, type, klass)
    end

    def includes!(includes)
      new_record? ? self : self.class.includes(includes).build(self).first
    end

    def update_attributes attributes
      attributes.each { |key, value| respond_to_non_id_writer?(key) ? write_attr(key, value) : self[key]=value }
      save
    end

    private
    def respond_to_non_id_writer? attr
      respond_to_writer?(attr) && attr.to_s != 'id'
    end

    def split_hash hash, method, split_by
      hash.try(method) { |k, _| send split_by, k }
    end

    def declared? attr
      self.class.attribute_names.include? attr.to_s
    end

    def respond_to_writer? attr
      respond_to? writer(attr)
    end

    def write_attr attr, value
      send writer(attr), value
    end

    def writer attr
      "#{attr}="
    end

    def related(direction, type, klass)
      id ?
          self.class.find_by_cypher(
              "start n=node({id}) match (n)#{'<' if direction == :incoming}-[:#{type}]-#{'>' if direction == :outgoing}(m#{":#{klass.label}" if klass}) return m",
              {id: id}, klass) :
          []
    end

    def destroy_associations include_associations
      rels=Neo.db.get_node_relationships(id)
      rels.nil? || rels.empty? || include_associations && rels.each { |rel| Neo.db.delete_relationship(rel) }
    end

    def create_or_update
      fresh = new_record?
      write
      association_cache.values.each { |assoc| assoc.save(fresh) }
    end

    def write
      now = to_neo(Time.now)
      try :updated_at=, now
      if persisted?
        write_properties
      else
        try :created_at=, now
        create_node_with_label
      end
    end

    def create_node_with_label
      self.id = get_id(Neo.db.create_node(all_attributes)).to_i
      Neo.db.set_label(id, self.class.label)
    end

    def write_properties
      Neo.db.reset_node_properties(id, all_attributes.select { |_, v| v.present? })
    end

    def all_attributes
      to_neo! attributes.except('id').merge(@hash)
    end

    def to_neo! attrs
      attrs.each { |k, v| attrs[k] = to_neo v }
    end

    def to_neo value
      case value
        when Time, DateTime
          value.utc.iso8601(3)
        when Date
          value.to_s
        else
          value
      end
    end
  end
end
