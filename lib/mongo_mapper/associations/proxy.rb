module MongoMapper
  module Associations
    class Proxy < BasicObject
      attr_reader :owner, :association
      
      def initialize(owner, association)
        @owner = owner
        @association = association
        @association.options[:extend].each { |ext| class << self; self; end.instance_eval { include ext } }
        reset
      end

      def respond_to?(*methods)
        (load_target && @target.respond_to?(*methods))
      end

      def reset
        @target = nil
      end

      def reload_target
        reset
        load_target
        self
      end

      def send(method, *args)
        metaclass_instance_methods = class << self; self; end.instance_methods
        
        if metaclass_instance_methods.any? { |m| m.to_s == method.to_s }
          return __send__(method, *args)
        end
        
        load_target
        @target.send(method, *args)
      end

      def replace(v)
        raise NotImplementedError
      end
      
      def inspect
        load_target
        @target.inspect
      end
      
      def nil?
        load_target
        @target.nil?
      end
      
      def ===(other)
        load_target
        other === @target
      end
      
      protected
        def method_missing(method, *args, &block)
          if load_target
            if block.nil?
              @target.send(method, *args)
            else
              @target.send(method, *args)  { |*block_args| block.call(*block_args) }
            end
          end
        end

        def load_target
          @target ||= find_target
        end

        def find_target
          raise NotImplementedError
        end
        
        # Array#flatten has problems with recursive arrays. Going one level
        # deeper solves the majority of the problems.
        def flatten_deeper(array)
          array.collect do |element|
            (element.respond_to?(:flatten) && !element.is_a?(Hash)) ? element.flatten : element
          end.flatten
        end
    end
  end
end
