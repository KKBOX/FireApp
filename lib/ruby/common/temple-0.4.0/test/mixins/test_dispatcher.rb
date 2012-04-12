require 'helper'

class FilterWithDispatcherMixin
  include Temple::Mixins::Dispatcher

  def on_test(arg)
    [:on_test, arg]
  end

  def on_test_check(arg)
    [:on_check, arg]
  end

  def on_second_test(arg)
    [:on_second_test, arg]
  end

  def on_seventh_level_level_level_level_level_test(arg)
    [:on_seventh_test, arg]
  end
end

class FilterWithDispatcherMixinAndOn < FilterWithDispatcherMixin
  def on(*args)
    [:on_zero, *args]
  end
end

describe Temple::Mixins::Dispatcher do
  before do
    @filter = FilterWithDispatcherMixin.new
  end

  it 'should return unhandled expressions' do
    @filter.call([:unhandled]).should.equal [:unhandled]
  end

  it 'should dispatch first level' do
    @filter.call([:test, 42]).should.equal [:on_test, 42]
  end

  it 'should dispatch second level' do
    @filter.call([:second, :test, 42]).should.equal [:on_second_test, 42]
  end

  it 'should dispatch second level if prefixed' do
    @filter.call([:test, :check, 42]).should.equal [:on_check, 42]
  end

  it 'should dispatch seventh level' do
    @filter.call([:seventh, :level, :level, :level, :level, :level, :test, 42]).should == [:on_seventh_test, 42]
  end

  it 'should dispatch zero level' do
    FilterWithDispatcherMixinAndOn.new.call([:foo,42]).should == [:on_zero, :foo, 42]
  end
end
