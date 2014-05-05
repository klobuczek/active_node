module ActiveNode
  class Graph
    include Neography::Rest::Helpers
    include FinderMethods, QueryMethods

    attr_reader :reflections, :matches, :klass, :loaded
    alias :loaded? :loaded

    delegate :to_xml, :to_yaml, :length, :collect, :map, :each, :all?, :include?, :to_ary, to: :to_a

    def initialize klass, *includes
      @klass = klass if klass < ActiveNode::Base
      @matches = []
      @reflections =[]
      @object_cache = {}
      @relationship_cache = {}
      @loaded_assoc_cache = {}
      @where = {}
      @includes = includes
      @offsets = {}
    end

    def all
      self
    end

    def count
      to_a.count
    end

    def includes *includes
      @includes += includes
      self
    end

    def where hash
      @where.merge! hash
      self
    end

    def limit count
      @limit = count
      self
    end

    def build *objects
      find objects.map { |o| o.is_a?(ActiveNode::Base) ? o.id.tap { |id| @object_cache[id]=o } : extract_id(o) }
    end

    def load
      parse_results execute unless loaded?
      self
    end

    def to_a
      load
      @records
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
      "limit #{@limit}" if @limit
    end

    def initial_match
      "match (n0#{label @klass})"
    end

    def execute
      Neo.db.execute_query(to_cypher, @where)
    end

    def to_cypher
      [initial_match, conditions, "with n0", limit_cond, query, 'return', list_with_rel(@reflections.size), 'order by', created_at_list(@reflections.size)].compact.join ' '
    end

    def parse_results results
      records = Set.new
      results['data'].each do |record|
        records << wrap(record.first, @klass)
        @reflections.each_with_index do |reflection, index|
          node_rel = record[2*index+1]
          node_rel = node_rel.last if node_rel.is_a? Array
          next unless node_rel
          owner = @object_cache[owner_id node_rel, reflection.direction]
          node = wrap record[2*index + 2], reflection.klass
          rel = reflection.klass.create_rel node_rel, node
          assoc = owner.association(reflection.name)
          assoc.rels_writer((assoc.rel_target || []) << rel) unless previously_loaded?(assoc)
        end
      end
      @loaded = true
      @records = records.to_a
    end

    def previously_loaded?(assoc)
      @loaded_assoc_cache[assoc] = assoc.rel_target unless @loaded_assoc_cache.key? assoc
      @loaded_assoc_cache[assoc]
    end

    def wrap(record, klass)
      @object_cache[extract_id record] ||= ActiveNode::Base.wrap(record, klass)
    end

    def owner_id relationship, direction
      extract_id relationship[direction == :incoming ? 'end' : 'start']
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
      comma_sep_list(num) { |i| [("r#{i}" if i>0), "n#{i}"] }
    end

    def comma_sep_list num, &block
      (0..num).map(&block).flatten.compact.join(', ')
    end

    def created_at_list num
      comma_sep_list(num) { |i| "n#{i}.created_at" }
    end

    def extract_id(id)
      get_id(id).to_i
    end
  end
end
