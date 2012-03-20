module Rhino
  module Ruby
    module AttributeAccess
      
      def self.has(object, name, scope)
        if object.respond_to?(name.to_s) || 
           object.respond_to?("#{name}=") # might have a writer but no reader
          return true
        end
        # try [](name) method :
        if object.respond_to?(:'[]') && object.method(:'[]').arity == 1
          return true if object[name]
        end
        yield
      end
      
      def self.get(object, name, scope)
        if object.respond_to?(name_s = name.to_s)
          method = object.method(name_s)
          if method.arity == 0 && # check if it is an attr_reader
            ( object.respond_to?("#{name}=") || object.instance_variables.include?("@#{name}") )
            begin
              return Rhino.to_javascript(method.call, scope)
            rescue => e
              raise Rhino::Ruby.wrap_error(e)
            end
          else
            return Function.wrap(method.unbind)
          end
        elsif object.respond_to?("#{name}=")
          return nil # it does have the property but is non readable
        end
        # try [](name) method :
        if object.respond_to?(:'[]') && object.method(:'[]').arity == 1
          if value = object[name]
            return Rhino.to_javascript(value, scope)
          end
        end
        yield
      end
      
      def self.put(object, name, value)
        if object.respond_to?(set_name = "#{name}=")
          return object.send(set_name, Rhino.to_ruby(value))
        end
        # try []=(name, value) method :
        if object.respond_to?(:'[]=') && object.method(:'[]=').arity == 2
          return object[name] = Rhino.to_ruby(value)
        end
        yield
      end
      
    end
  end
end