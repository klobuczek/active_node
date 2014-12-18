module ActiveNode
  class Graph
    MULTI_VALUE_METHODS = [:includes, :eager_load, :preload, :select, :group,
                           :order, :joins, :where, :having, :bind, :references,
                           :extending, :unscope]

    SINGLE_VALUE_METHODS = [:limit, :offset, :lock, :readonly, :from, :reordering,
                            :reverse_order, :distinct, :create_with, :uniq]

    VALUE_METHODS = MULTI_VALUE_METHODS + SINGLE_VALUE_METHODS

    include Neography::Rest::Helpers
    include FinderMethods, QueryMethods, Delegation

    attr_reader :reflections, :matches, :klass, :loaded
    alias :loaded? :loaded

    delegate :data, :extract_id, to: ActiveNode::Base

    def initialize klass, *includes
      @klass = klass if klass < ActiveNode::Base
      @matches = []
      @reflections =[]
      @object_cache = {}
      @relationship_cache = {}
      @loaded_assoc_cache = {}
      @where = {}
      @includes = includes
      @values = {}
      @offsets = {}
    end

    def all
      self
    end

    def includes *includes
      @includes += includes
      self
    end

    def where hash
      @where.merge! hash if hash
      self
    end

    def build *objects
      find objects.map { |o| o.is_a?(ActiveNode::Base) ? o.id.tap { |id| @object_cache[id]=o } : extract_id(o) }
    end

    def load
      parse_results execute['data'] unless loaded?
      self
    end

    def to_a
      load
      @records
    end

    def as_json(options = nil) #:nodoc:
      to_a.as_json(options)
    end

    # Returns size of the records.
    def size
      loaded? ? @records.length : count
    end

    # Returns true if there are no records.
    def empty?
      return @records.empty? if loaded?

      if limit_value == 0
        true
      else
        # FIXME: This count is not compatible with #select('authors.*') or other select narrows
        c = count
        c.respond_to?(:zero?) ? c.zero? : c.empty?
      end
    end

    # Returns true if there are any records.
    def any?
      if block_given?
        to_a.any? { |*block_args| yield(*block_args) }
      else
        !empty?
      end
    end

    # Returns true if there is more than one record.
    def many?
      if block_given?
        to_a.many? { |*block_args| yield(*block_args) }
      else
        limit_value ? to_a.many? : size > 1
      end
    end

    # Compares two relations for equality.
    def ==(other)
      case other
        when Graph
          other.to_cypher == to_cypher
        when Array
          to_a == other
      end
    end

    def pretty_print(q)
      q.pp(self.to_a)
    end

    # def first
    #   limit 1
    #   to_a.first
    # end

    def delete_all
      Neo.db.execute_query("#{initial_match} OPTIONAL MATCH (n0)-[r]-() DELETE n0,r")
    end

    private
    def query
      parse_paths(:n0, @klass, @includes)
      @matches.join ' '
    end

    def conditions
      cond = @where.map { |key, value| "#{cond_left(key)} #{cond_operator(value)} {#{key}}" }
      "where #{cond.join ' and '}" unless cond.empty?
    end

    def cond_left key
      key.to_s == 'id' ? "id(n0)" : "n0.#{key}"
    end

    def cond_operator value
      value.is_a?(Array) ? 'in' : '='
    end

    def limit_cond
      "limit #{limit_value}" if limit_value
    end

    def skip_cond
      "skip #{offset_value}" if offset_value
    end

    def initial_match
      "match (n0#{label @klass})"
    end

    def execute
      Neo.db.execute_query(to_cypher, sanitize_where)
    end

    def sanitize_where
      @where.each { |key, value| @where[key] = extract_id(value) if key.to_s == 'id' }
    end

    def to_cypher
      [initial_match, conditions, "with n0", order_list, skip_cond, limit_cond, query, 'return', list_with_rel(@reflections.size), order_list_with_defaults].compact.join ' '
    end

    def parse_results data
      @records = data.reduce(Set.new) { |set, record| set << wrap(record.first, @klass) }.to_a
      alternate_cells(data, 2) { |node, reflection| wrap node, reflection.klass }
      alternate_cells(data, 1) { |rel, reflection| wrap_rel [rel].flatten.last, reflection }
      @loaded = true
    end

    def alternate_cells data, shift
      data.each do |row|
        @reflections.each_with_index do |reflection, index|
          cell = row[2*index + shift]
          yield cell, reflection if cell
        end
      end
    end

    def previously_loaded?(assoc)
      @loaded_assoc_cache[assoc] = assoc.rel_target unless @loaded_assoc_cache.key? assoc
      @loaded_assoc_cache[assoc]
    end

    def wrap(record, klass)
      @object_cache[extract_id record] ||= ActiveNode::Base.wrap(record, klass)
    end

    def wrap_rel(rel, reflection)
      @relationship_cache[extract_id rel] ||= create_rel(rel, reflection)
    end

    def create_rel(rel, reflection)
      ActiveNode::Relationship.new(@object_cache[node_id rel, reflection, :other], data(rel)).tap do |relationship|
        assoc = @object_cache[node_id rel, reflection, :owner].association(reflection.name)
        assoc.rels_writer((assoc.rel_target || []) << relationship) unless previously_loaded?(assoc)
      end
    end

    def node_id relationship, reflection, side
      extract_id relationship[reflection.direction == {owner: :outgoing, other: :incoming}[side] ? 'start' : 'end']
    end

    def parse_paths as, klass, includes
      if includes.is_a?(Hash)
        includes.each do |key, value|
          if (value.is_a?(String) || value.is_a?(Numeric))
            add_match(as, klass, key, value)
          else
            parse_paths(as, klass, key)
            parse_paths(latest_alias, @reflections.last.klass, value)
          end
        end
      elsif includes.is_a?(Array)
        includes.each { |inc| parse_paths(as, klass, inc) }
      else
        add_match(as, klass, includes)
      end
    end

    def add_match from, klass, key, multiplicity=nil
      reflection = klass.reflect_on_association(key)
      @reflections << reflection
      matches << match(from, reflection, multiplicity)
    end

    def latest_alias
      "n#{@reflections.size}"
    end

    def match(start_var, reflection, multiplicity)
      "optional match (#{start_var})#{'<' if reflection.direction == :incoming}-[r#{@reflections.size}:#{reflection.type}#{multiplicity(multiplicity)}]-#{'>' if reflection.direction == :outgoing}(#{latest_alias}#{label reflection.klass})"
    end

    def label klass
      ":`#{klass.label}`" if klass
    end

    def multiplicity multiplicity
      multiplicity.is_a?(Numeric) ? "*1..#{multiplicity}" : multiplicity
    end

    def list_with_rel num
      comma_sep_list(0, num) { |i| [("r#{i}" if i>0), "n#{i}"] }
    end

    def comma_sep_list start, num, &block
      (0..num).map(&block).flatten.compact.join(', ')
    end

    def order_list_with_defaults
      "#{order_list}, #{comma_sep_list(1, @reflections.size) { |i| "n#{i}.created_at" }}"
    end

    def order_list
      if order_values.empty?
        order(:created_at) if @klass.respond_to? :created_at
        order(:id)
      end
      "order by #{build_order(:n0)}"
    end
  end
end
