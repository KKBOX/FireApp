require File.expand_path('../spec_helper', File.dirname(__FILE__))

shared_examples_for 'ScriptableObject', :shared => true do

  it "acts like a hash" do
    @object['foo'] = 'bar'
    @object['foo'].should == 'bar'
  end

  it "might be converted to a hash with string keys" do
    @object[42] = '42'
    @object[:foo] = 'bar'
    expect = @object.respond_to?(:to_h_properties) ? @object.to_h_properties : {}
    @object.to_h.should == expect.merge('42' => '42', 'foo' => 'bar')
  end
  
  it "yields properties with each" do
    @object['1'] = 1
    @object['3'] = 3
    @object['2'] = 2
    @object.each do |key, val|
      case key
        when '1' then val.should == 1
        when '2' then val.should == 2
        when '3' then val.should == 3
      end
    end
  end
  
end

describe "NativeObject" do
  
  before do
    @object = Rhino::JS::NativeObject.new
  end
  
  it_should_behave_like 'ScriptableObject'
  
end

describe "FunctionObject" do
      
  before do
    factory = Rhino::JS::ContextFactory.new
    context, scope = nil, nil
    factory.call do |ctx|
      context = ctx
      scope = context.initStandardObjects(nil, false)
    end
    factory.enterContext(context)
    
    to_string = java.lang.Object.new.getClass.getMethod(:toString)
    @object = Rhino::JS::FunctionObject.new('to_string', to_string, scope)
    @object.instance_eval do
      def to_h_properties
        { "arguments"=> nil, "prototype"=> {}, "name"=> "to_string", "arity"=> 0, "length"=> 0 }
      end
    end
  end

  after do
    Rhino::JS::Context.exit
  end
  
  it_should_behave_like 'ScriptableObject'
  
end

describe "NativeObject (scoped)" do
  
  before do
    factory = Rhino::JS::ContextFactory.new
    context, scope = nil, nil
    factory.call do |ctx|
      context = ctx
      scope = context.initStandardObjects(nil, false)
    end
    factory.enterContext(context)
    
    @object = context.newObject(scope)
  end
  
  after do
    Rhino::JS::Context.exit
  end
  
  it_should_behave_like 'ScriptableObject'  
  
  it 'routes rhino methods' do
    @object.prototype.should == {}
    @object.getTypeOf.should == 'object'
  end
  
  it 'raises on missing method' do
    lambda { @object.aMissingMethod }.should raise_error(NoMethodError)
  end
  
  it 'invokes JS function' do
    @object.hasOwnProperty('foo').should == false
    @object.toLocaleString.should == '[object Object]'
  end

  it 'puts JS property' do
    @object.has('foo', @object).should == false
    @object.foo = 'bar'
    @object.has('foo', @object).should == true
  end

  it 'gets JS property' do
    @object.put('foo', @object, 42)
    @object.foo.should == 42
  end
  
end

describe "NativeFunction" do
      
  before do
    factory = Rhino::JS::ContextFactory.new
    @context, @scope = nil, nil
    factory.call do |ctx|
      @context = ctx
      @scope = @context.initStandardObjects(nil, false)
    end
    factory.enterContext(@context)
    
    object = @context.newObject(@scope)
    @object = Rhino::JS::ScriptableObject.getProperty(object, 'toString')
    @object.instance_eval do
      def to_h_properties
        { "arguments"=> nil, "prototype"=> {}, "name"=> "toString", "arity"=> 0, "length"=> 0 }
      end
    end
  end

  after do
    Rhino::JS::Context.exit
  end
  
  it_should_behave_like 'ScriptableObject'
  
  it 'is callable' do
    # NOTE: no implicit or bound this thus this === global
    @object.call.should == '[object global]'
  end
  
  it 'might be bind and called' do
    @object.bind(@object).should be_a(Rhino::JS::Function)
    @object.bind(@object).call.should == '[object Function]'
  end
  
  it 'might be bind to a this context' do
    @object.bind(@object).should be_a(Rhino::JS::Function)
    @object.bind(@object).call.should == '[object Function]'
  end

  it 'might be bind to a this with args' do
    array = @context.newArray(@scope, [].to_java)
    push = Rhino::JS::ScriptableObject.getProperty(array, 'push')
    
    this = @context.newArray(@scope, [ 0 ].to_java)
    push.bind(this, 1, 2).call(3, 4)
    
    this.length.should == 5
    5.times { |i| this.get(i, this).should == i }
  end
  
  it 'might be applied' do
    an_obj = @context.newObject(@scope)
    @object.apply(an_obj).should == '[object Object]'
    
    array = @context.newArray(@scope, [].to_java)
    push = Rhino::JS::ScriptableObject.getProperty(array, 'splice')
    
    this = @context.newArray(@scope, [ 0, 3, 4 ].to_java)
    push.apply(this, 1, 0, 1, 2)
    
    this.length.should == 5
    5.times { |i| this.get(i, this).should == i }
  end
  
  it 'might get method-called' do
    @object.method(:apply).should == @object.method(:methodcall)
  end
  
end

describe "NativeFunction (constructor)" do
      
  before do
    factory = Rhino::JS::ContextFactory.new
    context, scope = nil, nil
    factory.call do |ctx|
      context = ctx
      scope = context.initStandardObjects(nil, false)
    end
    factory.enterContext(context)
    
    @object = Rhino::JS::ScriptableObject.getProperty(context.newObject(scope), 'constructor')
    @object.instance_eval do
      def to_h_properties
        {
          "arguments"=>nil, "prototype"=>{}, "name"=>"Object", "arity"=>1, "length"=>1,
          
          "getPrototypeOf"=> { "arguments"=>nil, "prototype"=>{}, "name"=>"getPrototypeOf", "arity"=>1, "length"=>1}, 
          "keys"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"keys", "arity"=>1, "length"=>1}, 
          "getOwnPropertyNames"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"getOwnPropertyNames", "arity"=>1, "length"=>1}, 
          "getOwnPropertyDescriptor"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"getOwnPropertyDescriptor", "arity"=>2, "length"=>2}, 
          "defineProperty"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"defineProperty", "arity"=>3, "length"=>3}, 
          "isExtensible"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"isExtensible", "arity"=>1, "length"=>1}, 
          "preventExtensions"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"preventExtensions", "arity"=>1, "length"=>1}, 
          "defineProperties"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"defineProperties", "arity"=>2, "length"=>2}, 
          "create"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"create", "arity"=>2, "length"=>2}, 
          "isSealed"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"isSealed", "arity"=>1, "length"=>1}, 
          "isFrozen"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"isFrozen", "arity"=>1, "length"=>1}, 
          "seal"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"seal", "arity"=>1, "length"=>1}, 
          "freeze"=>{"arguments"=>nil, "prototype"=>{}, "name"=>"freeze", "arity"=>1, "length"=>1}
        }
      end
    end
  end

  after do
    Rhino::JS::Context.exit
  end
  
  it_should_behave_like 'ScriptableObject'
  
  it 'is constructable' do
    @object.new.should == {}
  end
  
end
