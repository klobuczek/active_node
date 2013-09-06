module ActiveNode
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [
      :after_initialize, :after_find, :after_touch, :before_validation, :after_validation,
      :before_save, :around_save, :after_save, :before_create, :around_create,
      :after_create, :before_update, :around_update, :after_update,
      :before_destroy, :around_destroy, :after_destroy, :after_commit, :after_rollback
    ]

    module ClassMethods
      include ActiveModel::Callbacks
    end

    included do
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :initialize, :find, :touch, :only => :after
      define_model_callbacks :save, :create, :update, :destroy
    end

    def destroy include_relationships=false
      run_callbacks(:destroy) { super include_relationships }
    end

    def touch(*) #:nodoc:
      run_callbacks(:touch) { super }
    end

  private

    def create_or_update #:nodoc:
      run_callbacks(:save) { super }
    end

    def create_record #:nodoc:
      run_callbacks(:create) { super }
    end

    def update_record(*) #:nodoc:
      run_callbacks(:update) { super }
    end
  end
end
