module ActiveNode::Associations::Builder
  class Association #:nodoc:
    class << self
      attr_accessor :valid_options
    end

    self.valid_options = [:direction, :type, :class_name]

    attr_reader :model, :name, :options, :reflection

    def self.build(*args)
      new(*args).build
    end

    def initialize(model, name, options)
      raise ArgumentError, "association names must be a Symbol" unless name.kind_of?(Symbol)

      @model   = model
      @name    = name
      @options = options
    end

    def mixin
      @model
    end

    include Module.new { def build; end }

    def build
      validate_options
      define_accessors
      @reflection = model.create_reflection(macro, name, options, model)
      super # provides an extension point
      @reflection
    end

    def macro
      raise NotImplementedError
    end

    def valid_options
      Association.valid_options
    end

    def validate_options
      options.assert_valid_keys(valid_options)
    end

    def define_accessors
      define_readers
      define_writers
    end

    def define_readers
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(*args)
          association(:#{name}).reader(*args)
        end
      CODE
    end

    def define_writers
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}=(value)
          association(:#{name}).writer(value)
        end
      CODE
    end
  end
end
