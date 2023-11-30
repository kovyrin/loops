# frozen_string_literal: true

require 'spec_helper'

describe LoopLock do
  before :each do
    @lock = { entity_id: 1, loop: 'test' }
    LoopLock.reset!
  end

  describe '.lock' do
    it 'should lock unlocked entities' do
      expect(LoopLock.lock(@lock)).to be(true)
    end

    it 'should create a lock record for unlocked entities' do
      expect do
        LoopLock.lock(@lock)
      end.to change { LoopLock.locked?(@lock) }.from(false).to(true)
    end

    it 'should not lock an entity more than once' do
      expect(LoopLock.lock(@lock)).to be(true)
      expect(LoopLock.lock(@lock)).to be(false)
    end

    it 'should remove stale locks' do
      @lock[:timeout] = -1 # Expired 1 second ago :-)
      expect(LoopLock.lock(@lock)).to be(true)
      expect(LoopLock.lock(@lock)).to be(true)
    end
  end

  describe '.unlock' do
    before :each do
      LoopLock.lock(@lock)
    end

    it 'should remove lock records for a locked entities' do
      expect do
        expect(LoopLock.unlock(@lock)).to be(true)
      end.to change { LoopLock.locked?(@lock) }.from(true).to(false)
    end

    it 'should gracefully handle situations where we unlock a non-locked entities' do
      LoopLock.reset!
      expect do
        expect(LoopLock.unlock(@lock)).to be(false)
      end.to_not(change { LoopLock.locked?(@lock) })
    end
  end

  describe '.locked?' do
    it 'should return true for a locked entity' do
      LoopLock.lock(@lock)
      expect(LoopLock.locked?(@lock)).to be(true)
    end

    it 'should return false for a non-locked entity' do
      expect(LoopLock.locked?(@lock)).to be(false)
    end
  end
end
