module ActiveNode
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator # :nodoc:
      def validate_each(record, attribute, value)
        if value && other_matching_records(record, attribute, value).any?
          record.errors.add(attribute, :taken, value: value)
        end
      end

      private

      def other_matching_records(record, attribute, value)
        record.class.find_by_cypher(
            "Match (n:#{record.class.label}) where n.#{attribute} = {value}#{' and id(n) <> {id}' if record.persisted?} return n",
            value: value, id: record.id
        )
      end
    end
  end
end