module Less
  
  class Error < ::StandardError
    
    def initialize(cause, value = nil)
      @value = value
      message = nil
      if @value # 2 args passed
        message = @value['message']
      else # allow passing only value as first arg cause :
        if cause.respond_to?(:'[]') && message = cause['message']
          @value = cause
        end
      end
      
      if cause.is_a?(::Exception)
        @cause = cause
        super(message || cause.message)
      else
        super(message || cause)
      end
    end
    
    def cause
      @cause
    end
    
    def backtrace
      @cause ? @cause.backtrace : super
    end

    # function LessError(e, env) { ... }
    %w{ type filename stack extract }.each do |key|
      class_eval "def #{key}; @value && @value['#{key}']; end"
    end
    %w{ index line column }.each do |key|
      class_eval "def #{key}; @value && @value['#{key}'].to_i; end"
    end
    
  end
  
  class ParseError < Error; end
  
end