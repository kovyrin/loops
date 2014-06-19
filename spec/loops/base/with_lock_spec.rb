require 'spec_helper'

describe Loops::Base, '#with_lock' do
  before :each do
    @logger = double('Logger').as_null_object
    @loop = Loops::Base.new(@logger, 'simple', {})
  end

  context 'when an entity is not locked' do
    it 'should create lock on an item' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
        expect(LoopLock.locked?(:loop => 'rspec', :entity_id => 1)).to be(true)
      end
      expect(called).to be(true)
    end

    it 'should release lock on an item' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
      end
      expect(LoopLock.locked?(:loop => 'rspec', :entity_id => 1)).to be(false)
      expect(called).to be(true)
    end

    it 'should release lock on an item in case of error' do
      called = false
      expect {
        @loop.with_lock(1, 'rspec', 60) do
          called = true
          raise 'ouch'
        end
      }.to raise_error('ouch')
      expect(called).to be(true)
      expect(LoopLock.locked?(:loop => 'rspec', :entity_id => 1)).to be(false)
    end

    it 'should pass the lock timeout' do
      called = false
      @loop.with_lock(1, 'rspec', 0.2) do
        called = true
        expect(LoopLock.lock(:loop => 'rspec', :entity_id => 1)).to be(false)
        sleep(0.2)
        expect(LoopLock.lock(:loop => 'rspec', :entity_id => 1)).to be(true)
      end
      expect(called).to be(true)
    end

    it 'should release the lock on an item' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
      end
      expect(called).to be(true)
      expect(LoopLock.locked?(:loop => 'rspec', :entity_id => 1)).to be(false)
    end

    it 'should yield with entity_id value if block accepts the argument' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do |entity_id|
        called = true
        expect(entity_id).to eq(1)
      end
      expect(called).to be(true)
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
      expect(called).to be(false)
    end

    it 'should should not touch the lock object' do
      called = false
      @loop.with_lock(1, 'rspec', 60) do
        called = true
      end
      expect(LoopLock.locked?(:loop => 'rspec', :entity_id => 1)).to be(true)
      expect(called).to be(false)
    end
  end
end
