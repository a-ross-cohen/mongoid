# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $inc operations.
    #
    # @since 4.0.0
    module Incrementable
      extend ActiveSupport::Concern

      # Increment the provided fields by the corresponding values. Values can
      # be positive or negative, and if no value exists for the field it will
      # be set with the provided value.
      #
      # @example Increment the fields.
      #   document.inc(score: 10, place: 1, lives: -10)
      #
      # @param [ Hash ] increments The field/inc increment pairs.
      #
      # @return [ true, false ] If the increment succeeded.
      #
      # @since 4.0.0
      def inc(increments)
        prepare_atomic_operation do |coll, selector, ops|
          increments.each do |field, value|
            increment = value.__to_inc__
            normalized = database_field_name(field)
            current = attributes[normalized]
            attributes[normalized] = (current || 0) + increment
            ops[atomic_attribute_name(normalized)] = increment
          end
          coll.find(selector).update(positionally(selector, "$inc" => ops))
        end
      end
    end
  end
end