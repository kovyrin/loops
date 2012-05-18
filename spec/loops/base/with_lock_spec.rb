require 'spec_helper'

describe Loops::Base, '#with_lock' do
  before :each do
    @logger = mock('Logger').as_null_object
    @loop = Loops::Base.new(@logger, 'simple', {})
  end

  context 'when an entity is not locked' do
    it 'should create lock on an item' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
        LoopLock.locked?(:loop => 'rspec', :entity_id => 1).should be_true
      end
      called.should be_true
    end

    it 'should release lock on an item' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
      end
      LoopLock.locked?(:loop => 'rspec', :entity_id => 1).should be_false
      called.should be_true
    end

    it 'should release lock on an item in case of error' do
      called = false
      expect {
        @loop.with_lock(1, 'rspec', 60) do
          called = true
          raise 'ouch'
        end
      }.to raise_error('ouch')
      called.should be_true
      LoopLock.locked?(:loop => 'rspec', :entity_id => 1).should be_false
    end

    it 'should pass the lock timeout' do
      called = false
      @loop.with_lock(1, 'rspec', 0.2) do
        called = true
        LoopLock.lock(:loop => 'rspec', :entity_id => 1).should be_false
        sleep(0.2)
        LoopLock.lock(:loop => 'rspec', :entity_id => 1).should be_true
      end
      called.should be_true
    end

    it 'should release the lock on an item' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
      end
      called.should be_true
      LoopLock.locked?(:loop => 'rspec', :entity_id => 1).should be_false
    end

    it 'should yield with entity_id value if block accepts the argument' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do |entity_id|
        called = true
        entity_id.should == 1
      end
      called.should be_true
    end
  end

  context 'when an entity is already locked' do
    before :each do
      LoopLock.lock(:loop => 'rspec', :entity_id => 1)
    end

    it 'should should not yield' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
      end
      called.should be_false
    end

    it 'should should not touch the lock object' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
      end
      LoopLock.locked?(:loop => 'rspec', :entity_id => 1).should be_true
      called.should be_false
    end
  end
end
