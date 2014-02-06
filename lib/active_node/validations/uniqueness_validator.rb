module ActiveNode
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator # :nodoc:
      def validate_each(record, attribute, value)
        if value && !record.class.find_by_cypher("Match (n:#{record.class.label}) where n.#{attribute} = {value} return n", value: value).empty?
          record.errors.add(attribute, :taken, value: value)
        end
      end
    end
  end
end