module ActiveNode
  class Relationship
    include Neography::Rest::Helpers

    attr_accessor :other
    attr_reader :id

    def initialize other, props={}
      self.other = other
      @hash = props.with_indifferent_access
      @id = @hash.delete(:id).try(&:to_i)
    end

    delegate :[], to: :@hash
    delegate :[]=, to: :@hash

    def new_record?
      !id
    end

    def save(association)
      if new_record?
        from=association.owner
        to=other
        if association.reflection.direction == :incoming
          from, to = to, from
        end
        @id = get_id(Neo.db.create_relationship(association.reflection.type, from.id, to.id, @hash)).to_i
      else
        Neo.db.reset_relationship_properties(id, @hash.select { |_, v| v.present? })
      end
    end

    def self.create!(n, association)
      new(n).save(association)
    end
  end
end