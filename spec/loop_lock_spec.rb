require 'spec_helper'

describe LoopLock do
  before :each do
    @lock = { :entity_id => 1, :loop => 'test' }
    LoopLock.reset!
  end

  describe '.lock' do
    it 'should lock unlocked entities' do
      LoopLock.lock(@lock).should be_true
    end

    it 'should create a lock record for unlocked entities' do
      expect {
        LoopLock.lock(@lock)
      }.to change { LoopLock.locked?(@lock) }.from(false).to(true)
    end

    it 'should not lock an entity more than once' do
      LoopLock.lock(@lock).should be_true
      LoopLock.lock(@lock).should be_false
    end

    it 'should remove stale locks' do
      @lock[:timeout] = -1 # Expired 1 second ago :-)
      LoopLock.lock(@lock).should be_true
      LoopLock.lock(@lock).should be_true
    end
  end

  describe '.unlock' do
    before :each do
      LoopLock.lock(@lock)
    end

    it 'should remove lock records for a locked entities' do
      expect {
        LoopLock.unlock(@lock).should be_true
      }.to change { LoopLock.locked?(@lock) }.from(true).to(false)
    end

    it 'should gracefully handle situations where we unlock a non-locked entities' do
      LoopLock.reset!
      expect {
        LoopLock.unlock(@lock).should be_false
      }.to_not change { LoopLock.locked?(@lock) }
    end
  end

  describe '.locked?' do
    it 'should return true for a locked entity' do
      LoopLock.lock(@lock)
      LoopLock.locked?(@lock).should be_true
    end

    it 'should return false for a non-locked entity' do
      LoopLock.locked?(@lock).should be_false
    end
  end
end
