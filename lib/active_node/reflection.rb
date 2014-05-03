module ActiveNode
  # = Active Record Reflection
  module Reflection # :nodoc:
    extend ActiveSupport::Concern

    included do
      class_attribute :reflections
      self.reflections = {}
    end

    # Reflection enables to interrogate Active Record classes and objects
    # about their associations and aggregations. This information can,
    # for example, be used in a form builder that takes an Active Record object
    # and creates input fields for all of the attributes depending on their type
    # and displays the associations to other objects.
    #
    # MacroReflection class has info for AggregateReflection and AssociationReflection
    # classes.
    module ClassMethods
      def create_reflection(macro, name, options, model)
        case macro
          when :has_many, :has_one
            klass = options[:through] ? ThroughReflection : AssociationReflection
            reflection = klass.new(macro, name, options, model)
        end

        self.reflections = self.reflections.merge(name => reflection)
        reflection
      end

      # Returns an array of AssociationReflection objects for all the
      # associations in the class. If you only want to reflect on a certain
      # association type, pass in the symbol (<tt>:has_many</tt>, <tt>:has_one</tt>,
      # <tt>:belongs_to</tt>) as the first parameter.
      #
      # Example:
      #
      #   Account.reflect_on_all_associations             # returns an array of all associations
      #   Account.reflect_on_all_associations(:has_many)  # returns an array of all has_many associations
      #
      def reflect_on_all_associations(macro = nil)
        association_reflections = reflections.values.grep(AssociationReflection)
        macro ? association_reflections.select { |reflection| reflection.macro == macro } : association_reflections
      end

      # Returns the AssociationReflection object for the +association+ (use the symbol).
      #
      #   Account.reflect_on_association(:owner)             # returns the owner AssociationReflection
      #   Invoice.reflect_on_association(:line_items).macro  # returns :has_many
      #
      def reflect_on_association(association)
        reflection = reflections[association]
        reflection if reflection.is_a?(AssociationReflection)
      end

      # Returns an array of AssociationReflection objects for all associations which have <tt>:autosave</tt> enabled.
      def reflect_on_all_autosave_associations
        reflections.values.select { |reflection| reflection.options[:autosave] }
      end
    end

    # Base class for AggregateReflection and AssociationReflection. Objects of
    # AggregateReflection and AssociationReflection are returned by the Reflection::ClassMethods.
    #
    #   MacroReflection
    #     AggregateReflection
    #     AssociationReflection
    #       ThroughReflection
    class MacroReflection
      # Returns the name of the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns <tt>:balance</tt>
      # <tt>has_many :clients</tt> returns <tt>:clients</tt>
      attr_reader :name

      # Returns the macro type.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns <tt>:composed_of</tt>
      # <tt>has_many :clients</tt> returns <tt>:has_many</tt>
      attr_reader :macro

      attr_reader :scope

      # Returns the hash of options used for the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns <tt>{ class_name: "Money" }</tt>
      # <tt>has_many :clients</tt> returns +{}+
      attr_reader :options

      attr_reader :model


      def initialize(macro, name, options, model)
        @macro = macro
        @name = name
        @options = options
        @model = model
      end

      # Returns the class for the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns the Money class
      # <tt>has_many :clients</tt> returns the Client class
      def klass
        @klass ||= class_name.constantize
      end

      # Returns the class name for the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns <tt>'Money'</tt>
      # <tt>has_many :clients</tt> returns <tt>'Client'</tt>
      def class_name
        @class_name ||= (options[:class_name] || derive_class_name).to_s
      end

      def direction
        @direction ||= (options[:direction] || :outgoing)
      end

      def type
        @type ||= (options[:type] || derive_type)
      end

      # Returns +true+ if +self+ and +other_aggregation+ have the same +name+ attribute, +model+ attribute,
      # and +other_aggregation+ has an options hash assigned to it.
      def ==(other_aggregation)
        super ||
            other_aggregation.kind_of?(self.class) &&
                name == other_aggregation.name &&
                other_aggregation.options &&
                model == other_aggregation.model
      end

      private
      def derive_type
        direction == :outgoing ? name.to_s.singularize : @model.name.underscore
      end
    end


    # Holds all the meta-data about an association as it was specified in the
    # Active Record class.
    class AssociationReflection < MacroReflection
      #:nodoc:
      # Returns the target association's class.
      #
      #   class Author < ActiveRecord::Base
      #     has_many :books
      #   end
      #
      #   Author.reflect_on_association(:books).klass
      #   # => Book
      #
      # <b>Note:</b> Do not call +klass.new+ or +klass.create+ to instantiate
      # a new association object. Use +build_association+ or +create_association+
      # instead. This allows plugins to hook into association object creation.
      #def klass
      #  @klass ||= model.send(:compute_type, class_name)
      #end

      def initialize(*args)
        super
        @collection = [:has_many].include?(macro)
      end

      # Returns a new, unsaved instance of the associated class. +attributes+ will
      # be passed to the class's constructor.
      def build_association(attributes, &block)
        klass.new(attributes, &block)
      end

      def through_reflection
        nil
      end

      def source_reflection
        nil
      end

      # A chain of reflections from this one back to the owner. For more see the explanation in
      # ThroughReflection.
      def chain
        [self]
      end

      # Returns whether or not this association reflection is for a collection
      # association. Returns +true+ if the +macro+ is either +has_many+ or
      # +has_and_belongs_to_many+, +false+ otherwise.
      def collection?
        @collection
      end

      # Returns whether or not the association should be validated as part of
      # the parent's validation.
      #
      # Unless you explicitly disable validation with
      # <tt>validate: false</tt>, validation will take place when:
      #
      # * you explicitly enable validation; <tt>validate: true</tt>
      # * you use autosave; <tt>autosave: true</tt>
      # * the association is a +has_many+ association
      def validate?
        !options[:validate].nil? ? options[:validate] : (options[:autosave] == true || macro == :has_many)
      end

      def association_class
        case macro
          when :has_many
            if options[:through]
              Associations::HasManyThroughAssociation
            else
              Associations::HasManyAssociation
            end
          when :has_one
            if options[:through]
              Associations::HasOneThroughAssociation
            else
              Associations::HasOneAssociation
            end
        end
      end

      private
      def derive_class_name
        if direction == :outgoing
          class_name = type.to_s
        else
          class_name = name.to_s
          class_name = class_name.singularize if collection?
        end
        model.name.sub(/[^:]*$/, class_name.camelize)
      end
    end

    # Holds all the meta-data about a :through association as it was specified
    # in the Active Record class.
    class ThroughReflection < AssociationReflection #:nodoc:
    end
  end
end
