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

  it "should have a (shared) factory by default" do
    context1 = Rhino::Context.new
    context1.factory.should_not be nil
    context1.factory.should be_a(Rhino::JS::ContextFactory)
    
    context1.factory.should be Rhino::Context.default_factory
    
    context2 = Rhino::Context.new
    context2.factory.should be context1.factory
  end

  it "allows limiting instruction count" do
    context = Rhino::Context.new :restrictable => true
    context.instruction_limit = 100
    lambda {
      context.eval %Q{ for (var i = 0; i < 100; i++) Number(i).toString(); }
    }.should raise_error(Rhino::RunawayScriptError)
    
    context.instruction_limit = nil
    lambda {
      context.eval %Q{ for (var i = 0; i < 100; i++) Number(i).toString(); }
    }.should_not raise_error(Rhino::RunawayScriptError)
  end

  it "allows a timeout limit per context" do
    context1 = Rhino::Context.new :restrictable => true, :java => true
    context1.timeout_limit = 0.3
    
    context2 = Rhino::Context.new :restrictable => true, :java => true
    context2.timeout_limit = 0.3
    
    lambda {
      context2.eval %Q{ 
        var notDone = true; 
        (function foo() { 
          if (notDone) { 
            notDone = false;
            java.lang.Thread.sleep(300);
            foo();
          } 
        })(); 
      }
    }.should raise_error(Rhino::ScriptTimeoutError)
    
    lambda {
      context1.eval %Q{ 
        var notDone = true; 
        (function foo { 
          if (notDone) { 
            notDone = false;
            java.lang.Thread.sleep(100);
            foo();
          } 
        })(); 
      }
    }.should_not raise_error(Rhino::RunawayScriptError)
  end
  
  it "allows instruction and timeout limits at the same time" do
    context = Rhino::Context.new :restrictable => true, :java => true
    context.timeout_limit = 0.5
    context.instruction_limit = 10000
    lambda {
      context.eval %Q{ for (var i = 0; i < 100; i++) { java.lang.Thread.sleep(100); } }
    }.should raise_error(Rhino::ScriptTimeoutError)
    
    context = Rhino::Context.new :restrictable => true, :java => true
    context.timeout_limit = 0.5
    context.instruction_limit = 1000
    lambda {
      context.eval %Q{ for (var i = 0; i < 100; i++) { java.lang.Thread.sleep(10); } }
    }.should raise_error(Rhino::RunawayScriptError)
  end
  
end