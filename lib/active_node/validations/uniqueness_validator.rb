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
        record_class = record.class
        if record.persisted?
          record_class.find_by_cypher "Match (n:#{record_class.label}) where n.#{attribute} = {value} and id(n) <> {id} return n", value: value, id: record.id
        else
          record_class.find_by_cypher "Match (n:#{record_class.label}) where n.#{attribute} = {value} return n", value: value
        end
      end
    end
  end
end
