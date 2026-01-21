# frozen_string_literal: true

module Postal
  class MessageInspection

    attr_reader :message
    attr_reader :scope
    attr_reader :spam_checks
    attr_accessor :threat
    attr_accessor :threat_message
    attr_accessor :inspection_error

    def initialize(message, scope)
      @message = message
      @scope = scope
      @spam_checks = []
      @threat = false
      @inspection_error = false
    end

    def spam_score
      return 0 if @spam_checks.empty?

      @spam_checks.sum(&:score)
    end

    def scan
      MessageInspector.inspectors.each do |inspector|
        inspector.inspect_message(self)
      end
    end

    def successful?
      !@inspection_error
    end

    class << self

      def scan(message, scope)
        inspection = new(message, scope)
        inspection.scan
        inspection
      end

    end

  end
end
