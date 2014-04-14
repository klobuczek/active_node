module ActiveNode
  module Graph
    class Builder
      include Neography::Rest::Helpers

      attr_reader :reflections, :matches, :klass

      def initialize klass, *includes
        @klass = klass if klass < ActiveNode::Base
        @matches = []
        @reflections =[]
        @object_cache = {}
        @relationship_cache = {}
        @loaded_assoc_cache = {}
        parse_paths(:n0, klass, includes)
      end

      def build *objects
        ids = objects.map { |o| o.is_a?(ActiveNode::Base) ? o.id.tap { |id| @object_cache[id]=o } : o }
        parse_results execute(ids.compact)
        @object_cache.slice(*ids).values
      end

      private
      def query
        @matches.join " "
      end

      def execute(ids)
        q="start n0=node({ids}) #{query}#{"where n0#{label @klass}" if @klass} return #{list_with_rel(@reflections.size)} order by #{created_at_list(@reflections.size)}"
        Neo.db.execute_query(q, ids: ids)
      end

      def parse_results results
        results['data'].each do |record|
          wrap(record.first, @klass)
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
        ":#{klass.label}" if klass
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
end
