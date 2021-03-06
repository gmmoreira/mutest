module Mutest
  module AST
    module Regexp
      class Transformer
        # Transformer for regexp quantifiers
        class Quantifier < self
          # Mapper from `Regexp::Expression` to `Parser::AST::Node`
          class ExpressionToAST < Transformer::ExpressionToAST
            # Transform quantifier into node
            #
            # @return [Parser::AST::Node]
            def call
              ast(expression.min, expression.max)
            end

            private

            # Custom `type` for quantifiers which use `mode` instead of `type`
            #
            # @return [Symbol]
            def type
              :"regexp_#{expression.mode}_#{expression.token}"
            end
          end # ExpressionToAST

          # Mapper from `Parser::AST::Node` to `Regexp::Expression`
          class ASTToExpression < Transformer::ASTToExpression
            include NamedChildren

            children :min, :max, :subject

            Quantifier = Class.new.include(Concord::Public.new(:type, :suffix, :mode))

            QUANTIFIER_MAP = IceNine.deep_freeze({
              regexp_greedy_zero_or_more:     [:zero_or_more, '*',  :greedy],
              regexp_greedy_one_or_more:      [:one_or_more,  '+',  :greedy],
              regexp_greedy_zero_or_one:      [:zero_or_one,  '?',  :greedy],
              regexp_possessive_zero_or_one:  [:zero_or_one,  '?+', :possessive],
              regexp_reluctant_zero_or_more:  [:zero_or_more, '*?', :reluctant],
              regexp_reluctant_one_or_more:   [:one_or_more,  '+?', :reluctant],
              regexp_possessive_zero_or_more: [:zero_or_more, '*+', :possessive],
              regexp_possessive_one_or_more:  [:one_or_more,  '++', :possessive],
              regexp_greedy_interval:         [:interval,     '',   :greedy],
              regexp_reluctant_interval:      [:interval,     '?',  :reluctant],
              regexp_possessive_interval:     [:interval,     '+',  :possessive]
            }.map { |ast_type, arguments| [ast_type, Quantifier.new(*arguments)] }.to_h)

            private

            # Transform ast into quantifier attached to expression
            #
            # @return [Regexp::Expression::Base]
            def transform
              Regexp.to_expression(subject).dup.tap do |expression|
                expression.quantify(type, text, min, max, mode)
              end
            end

            # Quantifier text
            #
            # @return [String]
            def text
              if type.equal?(:interval)
                Interval.new(min, max).to_s + suffix
              else
                suffix
              end
            end

            # Type of quantifier
            #
            # @return [Symbol] :zero_or_more, :one_or_more, or :interval
            def type
              quantifier.type
            end

            # Regexp symbols used to specify quantifier
            #
            # @return [String]
            def suffix
              quantifier.suffix
            end

            # The quantifier "mode"
            #
            # @return [Symbol] :greedy, :possessive, or :reluctant
            def mode
              quantifier.mode
            end

            # Quantifier mapping information for current node
            #
            # @return [Quantifier]
            def quantifier
              QUANTIFIER_MAP.fetch(node.type)
            end

            class Interval
              include Concord.new(:min, :max)

              def initialize(*)
                super

                unless valid_min? && valid_max?
                  fail ArgumentError, 'Unexpected quantifier interval bound.'
                end
              end

              def to_s
                "{#{compacted_interval.join(',')}}"
              end

              private

              def compacted_interval
                [min, max].map { |bound| bound if bound > 0 }.uniq
              end

              def valid_min?
                min >= 0
              end

              def valid_max?
                max > 0 || max.equal?(-1)
              end
            end # Interval
          end # ASTToExpression

          ASTToExpression::QUANTIFIER_MAP.keys.each(&method(:register))
        end # Quantifier
      end # Transformer
    end # Regexp
  end # AST
end # Mutest
