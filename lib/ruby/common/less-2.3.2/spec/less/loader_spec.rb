require 'spec_helper'
require 'stringio'

describe Less::Loader do
  
  describe 'eval console.log()' do
    
    it 'should write message to $stdout' do
      stdout = $stdout; io_stub = StringIO.new
      begin
        $stdout = io_stub
        subject.environment.runtime.eval("console.log('log much?');")
      ensure
        $stdout = stdout
      end
      io_stub.string.should == "log much?\n"
    end
    
    it 'should write messages to $stdout' do
      stdout = $stdout; io_stub = StringIO.new
      begin
        $stdout = io_stub
        subject.environment.runtime.eval("console.log('1','2','3');")
      ensure
        $stdout = stdout
      end
      io_stub.string.should == "1, 2, 3\n"
    end
    
  end

  describe 'eval process.exit()' do
    
    process = Less::Loader::Process
    
    it 'should not raise an error' do
      # process = double("process")
      process.any_instance.should_receive(:warn) do |msg| 
        msg.should match(/JS process\.exit\(-2\)/)
      end
      subject.environment.runtime.eval("process.exit(-2);")
    end
    
  end
  
end
