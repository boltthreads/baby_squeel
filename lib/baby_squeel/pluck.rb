module BabySqueel
  class Pluck # :nodoc:
    # In Active Record 4.2, #pluck chokes when you give it
    # Arel. It calls #to_s on whatever you pass in. So the
    # hacky solution is to wrap the node in a class that
    # returns the node when you call #to_s. Then, it works!
    #
    # In Active Record 5, #pluck accepts Arel, so we won't
    # bother to use this there.

    if ::ActiveRecord::VERSION::MAJOR >= 5
      def self.wrap(node); node; end
    else
      def self.wrap(node); new(node); end
    end

    def initialize(node)
      @node = node
    end

    def to_s
      @node
    end
  end
end
