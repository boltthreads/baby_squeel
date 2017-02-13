require 'baby_squeel/calculation'
require 'baby_squeel/pluck'

module BabySqueel
  module ActiveRecord
    module Calculations
      def plucking(&block)
        pluck Pluck.wrap(DSL.evaluate(self, &block))
      end

      def counting(&block)
        count Calculation.new(DSL.evaluate(self, &block))
      end

      def summing(&block)
        sum Calculation.new(DSL.evaluate(self, &block))
      end

      def averaging(&block)
        average Calculation.new(DSL.evaluate(self, &block))
      end

      def minimizing(&block)
        minimum Calculation.new(DSL.evaluate(self, &block))
      end

      def maximizing(&block)
        maximum Calculation.new(DSL.evaluate(self, &block))
      end

      # @override
      def aggregate_column(column_name)
        if column_name.kind_of? Calculation
          column_name.node
        else
          super
        end
      end

      if ::ActiveRecord::VERSION::MAJOR < 5
        # @override
        def type_for(field)
          if field.kind_of? Calculation
            field
          else
            super
          end
        end
      end
    end
  end
end
