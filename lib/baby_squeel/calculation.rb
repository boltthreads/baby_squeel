module BabySqueel
  class Calculation # :nodoc:
    attr_reader :node

    def initialize(node)
      @node = node
    end

    # This is only used in 4.2. We're just pretending to be
    # a database column to fake the casting here.
    def type_cast_from_database(value)
      value
    end

    # In Active Record 5, we don't *need* this class to make
    # calculations work. They happily accept arel. However,
    # when grouping with a calculation, there's a really,
    # really weird alias name. It calls #to_s on the Arel.
    #
    # If this were not addressed, it would likely break query
    # caching because the alias would have a unique name every
    # time.
    def to_s
      names = node.map do |child|
        if child.kind_of?(String) || child.kind_of?(Symbol)
          child.to_s
        elsif child.respond_to?(:name)
          child.name.to_s
        end
      end

      names.compact.uniq.join('_')
    end
  end
end
