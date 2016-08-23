# frozen_string_literal: true
module PaymentProcessor
  module Braintree
    class ErrorProcessing
      # Collection of error codes, generated by braintree for invalid
      # customer/credit card transaction data.
      #
      # See https://developers.braintreepayments.com/reference/general/validation-errors/all/ruby
      # for code definitions.
      #
      USER_ERROR_CODES = [
        (81_801..81_813),
        (81_501..81_503),
        (91_814..91_826),
        (81_604..81_608),
        (81_613..81_616),
        (81_709..81_717),
        (91_723..91_726),
        81_827,
        91_803,
        81_601,
        81_723,
        81_703,
        81_706,
        81_707,
        81_736,
        81_737,
        81_528,
        81_509
      ].map { |code| code.is_a?(Range) ? code.to_a : code }
                         .flatten
                         .freeze

      FILTER = -> (error) { USER_ERROR_CODES.include?(error.code.to_i) }

      # locale is unused, added to match API for GoCardless
      def initialize(response, _locale: nil)
        @response = response
      end

      def process
        return user_errors if user_errors.any?
        return processor_errors if processor_errors.any?

        raise_system_errors if system_errors.any?
      end

      private

      def raise_system_errors
        raise ::Braintree::ValidationsFailed, error_messages
      end

      def error_messages
        system_errors.map { |e| "#{e.message} (#{e.code} on #{e.attribute})" }.join(', ')
      end

      def user_errors
        @user_errors ||= errors.select(&FILTER)
      end

      def system_errors
        @system_errors ||= errors.reject(&FILTER)
      end

      def errors
        @response.errors
      end

      def processor_errors
        if @response.transaction
          case @response.transaction.status
          when 'processor_declined'
            processor_declined_error
          when 'gateway_rejected'
            gateway_rejected_error
          when 'settlement_declined'
            settlement_declined_error
          else
            []
          end
        else
          []
        end
      end

      def processor_declined_error
        [{
          declined: true,
          code: @response.transaction.processor_response_code,
          message: @response.transaction.processor_response_text
        }]
      end

      def settlement_declined_error
        [{
          declined: true,
          code: @response.transaction.processor_settlement_response_code,
          message: @response.transaction.processor_settlement_response_text
        }]
      end

      def gateway_rejected_error
        [{
          declined: true,
          code: '',
          message: @response.transaction.gateway_rejection_reason
        }]
      end
    end
  end
end
