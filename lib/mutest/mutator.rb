module Mutest
  # Generator for mutations
  class Mutator
    REGISTRY = Registry.new

    include Adamantium::Flat, Concord.new(:input, :parent), AbstractType, Procto.call(:output)

    # Lookup and invoke dedicated AST mutator
    #
    # @param node [Parser::AST::Node]
    # @param parent [nil,Mutest::Mutator::Node]
    #
    # @return [Set<Parser::AST::Node>]
    def self.mutate(node, parent = nil)
      self::REGISTRY.lookup(node.type).call(node, parent)
    end

    # Register node class handler
    #
    # @return [undefined]
    def self.handle(*types)
      types.each do |type|
        self::REGISTRY.register(type, self)
      end
    end
    private_class_method :handle

    # Return output
    #
    # @return [Set<Parser::AST::Node>]
    attr_reader :output

    private

    # Initialize object
    #
    # @param [Object] input
    # @param [Object] parent
    # @param [#call(node)] block
    #
    # @return [undefined]
    def initialize(_input, _parent = nil)
      super

      @output = Set.new

      dispatch
    end

    # Test if generated object is not guarded from emitting
    #
    # @param [Object] object
    #
    # @return [Boolean]
    def new?(object)
      !object.eql?(input)
    end

    # Dispatch node generations
    #
    # @return [undefined]
    abstract_method :dispatch

    # Emit generated mutation if object is not equivalent to input
    #
    # @param [Object] object
    #
    # @return [undefined]
    def emit(object)
      return unless new?(object)

      output << object
    end

    # Shortcut to create a new unfrozen duplicate of input
    #
    # @return [Object]
    def dup_input
      input.dup
    end

    # Mutate child nodes within source path
    #
    # @return [Set<Parser::AST::Node>]
    def mutate(*args)
      self.class.mutate(*args)
    end

    # Run input with mutator
    #
    # @return [undefined]
    def run(mutator)
      mutate_with(mutator, input)
    end

    # Mutate nodes using a specific mutator class
    #
    # @yield [Object] value emitted by provided mutator
    #
    # @return [undefined]
    def mutate_with(mutator, nodes, &block)
      block ||= method(:emit)

      mutator.call(nodes).each(&block)
    end
  end # Mutator
end # Mutest
