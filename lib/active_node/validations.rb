module ActiveNode
  module Validations
    extend ActiveSupport::Concern
    include ActiveModel::Validations

    # The validation process on save can be skipped by passing <tt>validate: false</tt>.
    # The regular Base#save method is replaced with this when the validations
    # module is mixed in, which it is by default.
    def save(options={})
      perform_validations(options) ? super : false
    end

    # Runs all the validations within the specified context. Returns +true+ if
    # no errors are found, +false+ otherwise.
    #
    # If the argument is +false+ (default is +nil+), the context is set to <tt>:create</tt> if
    # <tt>new_record?</tt> is +true+, and to <tt>:update</tt> if it is not.
    #
    # Validations with no <tt>:on</tt> option will run no matter the context. Validations with
    # some <tt>:on</tt> option will only run in the specified context.
    def valid?(context = nil)
      context ||= (new_record? ? :create : :update)
      output = super(context)
      errors.empty? && output
    end

    protected

    def perform_validations(options={}) # :nodoc:
      options[:validate] == false || valid?(options[:context])
    end
  end
end
