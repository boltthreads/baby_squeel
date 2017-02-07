require 'baby_squeel/join_expression'
require 'baby_squeel/join_dependency/builder'

module BabySqueel
  class Table
    attr_accessor :_on, :_table
    attr_writer :_join

    def initialize(arel_table)
      @_table = arel_table
    end

    # See Arel::Table#[]
    def [](key)
      Nodes::Attribute.new(self, key)
    end

    def _join
      @_join ||= Arel::Nodes::InnerJoin
    end

    # Alias a table. This is only possible when joining
    # an association explicitly.
    def alias(alias_name)
      clone.alias! alias_name
    end

    def alias!(alias_name) # :nodoc:
      self._table = _table.alias(alias_name)
      self
    end

    # Instruct the table to be joined with a LEFT OUTER JOIN.
    def outer
      clone.outer!
    end

    def outer! # :nodoc:
      self._join = Arel::Nodes::OuterJoin
      self
    end

    # Instruct the table to be joined with an INNER JOIN.
    def inner
      clone.inner!
    end

    def inner! # :nodoc:
      self._join = Arel::Nodes::InnerJoin
      self
    end

    # Specify an explicit join.
    def on(node = nil, &block)
      clone.on!(node, &block)
    end

    def on!(node = nil, &block) # :nodoc:
      if node.nil? && !block_given?
        raise 'FIXME: A proper error should be risen here!'
      end

      self._on = node || evaluate(&block)
      self
    end

    # Evaluates a DSL block. If arity is given, this method
    # `yield` itself, rather than `instance_eval`.
    def evaluate(&block)
      if block.arity.zero?
        instance_eval(&block)
      else
        yield(self)
      end
    end

    # When referencing a joined table, the tables that
    # attributes reference can change (due to aliasing).
    # This method allows BabySqueel::Nodes::Attribute
    # instances to find what their alias will be.
    def find_alias(associations = [])
      builder = JoinDependency::Builder.new(_scope.all)
      builder.ensure_associated _arel(associations)
      builder.find_alias(associations)
    end

    # This method will be invoked by BabySqueel::Nodes::unwrap. When called,
    # there are three possible outcomes:
    #
    # 1. Join explicitly using an on clause. Just return Arel.
    # 2. Implicit join without using an outer join. In this case, we'll just
    #    give a hash to Active Record, and join the normal way.
    # 3. Implicit join using an outer join. In this case, we need to use
    #    Polyamorous to build the join. We'll return a JoinExpression.
    #
    def _arel(associations = [])
      if _on
        _join.new(_table, Arel::Nodes::On.new(_on))
      elsif associations.any?(&:needs_polyamorous?)
        JoinExpression.new(associations)
      elsif associations.any?
        associations.reverse.inject({}) do |names, assoc|
          { assoc._reflection.name => names }
        end
      end
    end

    private

    def not_found_error!
      raise NotImplementedError, 'BabySqueel::Table will never raise a NotFoundError'
    end

    def resolve(name)
      if _table.kind_of?(Arel::Nodes::TableAlias) && _table.name == name.to_s
        self
      else
        self[name]
      end
    end

    def respond_to_missing?(name, *)
      resolve(name).present? || super
    end

    def method_missing(name, *args, &block)
      return super if !args.empty? || block_given?
      resolve(name) || not_found_error!(name)
    end
  end
end
