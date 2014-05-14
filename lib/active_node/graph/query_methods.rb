module ActiveNode
  module QueryMethods
    Graph::MULTI_VALUE_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_values                   # def select_values
          @values[:#{name}] || []            #   @values[:select] || []
        end                                  # end
                                             #
        def #{name}_values=(values)          # def select_values=(values)
          raise ImmutableGraph if @loaded    #   raise ImmutableGraph if @loaded
          @values[:#{name}] = values         #   @values[:select] = values
        end                                  # end
      CODE
    end

    (Graph::SINGLE_VALUE_METHODS - [:create_with]).each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_value                    # def readonly_value
          @values[:#{name}]                  #   @values[:readonly]
        end                                  # end
      CODE
    end

    Graph::SINGLE_VALUE_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_value=(value)            # def readonly_value=(value)
          raise ImmutableGraph if @loaded    #   raise ImmutableGraph if @loaded
          @values[:#{name}] = value          #   @values[:readonly] = value
        end                                  # end
      CODE
    end

    # Specifies a limit for the number of records to retrieve.
    #
    #   User.limit(10) # generated SQL has 'LIMIT 10'
    #
    #   User.limit(10).limit(20) # generated SQL has 'LIMIT 20'
    def limit(value)
      spawn.limit!(value)
    end

    def limit!(value) # :nodoc:
      self.limit_value = value
      self
    end

    # Specifies the number of rows to skip before returning rows.
    #
    #   User.offset(10) # generated SQL has "OFFSET 10"
    #
    # Should be used with order.
    #
    #   User.offset(10).order("name ASC")
    def offset(value)
      spawn.offset!(value)
    end

    def offset!(value) # :nodoc:
      self.offset_value = value
      self
    end


    # Allows to specify an order attribute:
    #
    #   User.order('name')
    #   => SELECT "users".* FROM "users" ORDER BY name
    #
    #   User.order('name DESC')
    #   => SELECT "users".* FROM "users" ORDER BY name DESC
    #
    #   User.order('name DESC, email')
    #   => SELECT "users".* FROM "users" ORDER BY name DESC, email
    #
    #   User.order(:name)
    #   => SELECT "users".* FROM "users" ORDER BY "users"."name" ASC
    #
    #   User.order(email: :desc)
    #   => SELECT "users".* FROM "users" ORDER BY "users"."email" DESC
    #
    #   User.order(:name, email: :desc)
    #   => SELECT "users".* FROM "users" ORDER BY "users"."name" ASC, "users"."email" DESC
    def order(*args)
      check_if_method_has_arguments!(:order, args)
      spawn.order!(*args)
    end

    def order!(*args) # :nodoc:
      preprocess_order_args(args)

      self.order_values += args
      self
    end

    # Replaces any existing order defined on the relation with the specified order.
    #
    #   User.order('email DESC').reorder('id ASC') # generated SQL has 'ORDER BY id ASC'
    #
    # Subsequent calls to order on the same relation will be appended. For example:
    #
    #   User.order('email DESC').reorder('id ASC').order('name ASC')
    #
    # generates a query with 'ORDER BY id ASC, name ASC'.
    def reorder(*args)
      check_if_method_has_arguments!(:reorder, args)
      spawn.reorder!(*args)
    end

    def reorder!(*args) # :nodoc:
      preprocess_order_args(args)

      self.reordering_value = true
      self.order_values = args
      self
    end

    # Reverse the existing order clause on the relation.
    #
    #   User.order('name ASC').reverse_order # generated SQL has 'ORDER BY name DESC'
    def reverse_order
      spawn.reverse_order!
    end

    def reverse_order! # :nodoc:
      self.reverse_order_value = !reverse_order_value
      self
    end

    private

    def build_order(prefix)
      orders = order_values.uniq
      orders.reject!(&:blank?)
      orders = reverse_sql_order(orders) if reverse_order_value

      orders.map {|o| "#{prefix}.#{o}"}.join(', ')
    end

    def reverse_sql_order(order_query)
      # order_query = ["#{quoted_table_name}.#{quoted_primary_key} ASC"] if order_query.empty?

      order_query.flat_map do |o|
        case o
          when String
            split_order(o).map! do |s|
              s.gsub!(/\sasc\Z/i, ' DESC') || s.gsub!(/\sdesc\Z/i, ' ASC') || s.concat(' DESC')
            end
          else
            o
        end
      end
    end

    def spawn
      clone
    end

    def split_order s
      s.to_s.split(',').map! &:strip
    end

    def preprocess_order_args(order_args)
      order_args.flatten!
      validate_order_args(order_args)

      # references = order_args.grep(String)
      # references.map! { |arg| arg =~ /^([a-zA-Z]\w*)\.(\w+)/ && $1 }.compact!
      # references!(references) if references.any?

      order_args.map! do |arg|
        case arg
          when Symbol
            arg = klass.attribute_alias(arg) if klass.try :attribute_alias?, arg
            arg.to_s
          when Hash
            arg.map { |field, dir|
              field = klass.attribute_alias(field) if klass.try :attribute_alias?, arg
              "#{field} #{dir}"
            }
          when String
            split_order(arg)
          else
            arg
        end
      end.flatten!
    end

    # Checks to make sure that the arguments are not blank. Note that if some
    # blank-like object were initially passed into the query method, then this
    # method will not raise an error.
    #
    # Example:
    #
    #    Post.references()   # => raises an error
    #    Post.references([]) # => does not raise an error
    #
    # This particular method should be called with a method_name and the args
    # passed into that method as an input. For example:
    #
    # def references(*args)
    #   check_if_method_has_arguments!("references", args)
    #   ...
    # end
    def check_if_method_has_arguments!(method_name, args)
      if args.blank?
        raise ArgumentError, "The method .#{method_name}() must contain arguments."
      end
    end

    def validate_order_args(args)
      args.grep(Hash) do |h|
        unless (h.values - [:asc, :desc]).empty?
          raise ArgumentError, 'Direction should be :asc or :desc'
        end
      end
    end
  end
end
