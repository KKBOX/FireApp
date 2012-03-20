require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Rhino::Context do

  describe "Initalizing Standard Javascript Objects" do
    it "provides the standard objects without java integration by default" do
      Rhino::Context.open do |cxt|
        cxt["Object"].should_not be_nil
        cxt["Math"].should_not be_nil
        cxt["String"].should_not be_nil
        cxt["Function"].should_not be_nil
        cxt["Packages"].should be_nil
        cxt["java"].should be_nil
        cxt["org"].should be_nil
        cxt["com"].should be_nil
      end
    end

    it "provides unsealed standard object by default" do
      Rhino::Context.open do |cxt|
        cxt.eval("Object.foop = 'blort'")
        cxt["Object"]['foop'].should == 'blort'
      end
    end

    it "allows you to scope the context to an object" do
      class MyScope
        def foo(*args); args && 'bar'; end
      end
      Rhino::Context.open(:with => MyScope.new) do |ctx|
        ctx.eval("foo()").should == 'bar'
      end
    end

    it "allows you to seal the standard objects so that they cannot be modified" do
      Rhino::Context.open(:sealed => true) do |cxt|
        lambda {
          cxt.eval("Object.foop = 'blort'")
        }.should raise_error(Rhino::JSError)

        lambda {
          cxt.eval("Object.prototype.toString = function() {}")
        }.should raise_error(Rhino::JSError)
      end
    end

    it "allows java integration to be turned on when initializing standard objects" do
      Rhino::Context.open(:java => true) do |cxt|
        cxt["Packages"].should_not be_nil
      end
    end
  end

  it "should get default interpreter version" do
    context = Rhino::Context.new
    
    context.version.should == 0
  end
  
  it "should set interpreter version" do
    context = Rhino::Context.new
    context.version = 1.6
    context.version.should == 1.6
    
    context.version = '1.7'
    context.version.should == 1.7
  end
  
end