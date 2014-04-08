require 'active_support/core_ext/hash/indifferent_access'

module ActiveNode
  module Persistence
    extend ActiveSupport::Concern
    include Neography::Rest::Helpers

    included do
      extend Neography::Rest::Helpers
      attribute :id
    end

    module ClassMethods
      def timestamps
        attribute :created_at, type: String
        attribute :updated_at, type: String
      end

      def find ids
        array = new_instances(Neo.db.get_nodes([ids].flatten))
        ids.is_a?(Array) ? array : array.first
      end

      def find_by_cypher query, params={}, klass=nil
        wrap(Neo.db.execute_query(query, params)['data'].map(&:first), klass)
      end

      def all
        new_instances(Neo.db.get_nodes_labeled(label), self)
      end

      def label
        name
      end

      def wrap node, klass=nil
        node.is_a?(Array) ? new_instances(node, klass) : new_instance(node, klass)
      end

      def wrap_rel rel, node, klass
        ActiveNode::Relationship.new wrap(node, klass), rel['data'].merge(id: get_id(rel).to_i)
      end

      def active_node_class(class_name, default_klass=nil)
        klass = Module.const_get(class_name) rescue nil
        klass && klass < ActiveNode::Base && klass || default_klass
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
        send "#{attr}=", value
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

    def relationships(reflection, *associations)
      id ?
          Neo.db.execute_query(
              "start n=node({id}) match #{match reflection}#{optional_match reflection, associations} return #{list_with_rel reflection.name, *associations} order by #{created_at_list reflection.name, *associations}",
              {id: id})['data'].map { |rel_node| self.class.wrap_rel rel_node[0], rel_node[1], reflection.klass } :
          []
    end

    private
    def parse_result klass, result, associations
      node_map = {}
      result.each do |record|
        (node_map[extract_id(record[1])] ||= wrap_rel(record[0], record[1], klass))
      end
    end

    def extract_id(id)
      get_id(id).to_i
    end

    def match(reflection, start_var='n')
      "(#{start_var})#{'<' if reflection.direction == :incoming}-[#{reflection.name}_rel:#{reflection.type}]-#{'>' if reflection.direction == :outgoing}(#{reflection.name}#{label reflection.klass})"
    end

    def optional_match reflection, associations
      return if associations.empty?
      " optional match " + comma_sep_list(associations.map { |association| match(reflection.klass.reflect_on_association(association), association) })
    end

    def label klass
      ":#{klass.label}" if klass
    end

    def list_with_rel *names
      comma_sep_list names.map { |name| ["#{name}_rel", name] }.flatten
    end

    def comma_sep_list *items
      items.join(', ')
    end

    def created_at_list *names
      comma_sep_list names.map { |name| "#{name}.created_at" }
    end

    def split_hash hash, method, split_by
      hash.try(method) { |k, _| send split_by, k }
    end

    def declared? attr
      self.class.attribute_names.include? attr.to_s
    end

    def respond_to_writer? attr
      respond_to? "#{attr}="
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
      write; true
      association_cache.values.each { |assoc| assoc.save(fresh) }
    end

    def write
      now = Time.now.utc.iso8601(3)
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
      attributes.merge(@hash)
    end

  end
end
