module ActiveNode

  # = Active Node Errors
  #
  # Generic Active Node exception class.
  class ActiveNodeError < StandardError
  end

  # Raised by ActiveRecord::Base.save! and ActiveRecord::Base.create! methods when record cannot be
  # saved because record is invalid.
  class RecordNotSaved < ActiveNodeError
  end
end
