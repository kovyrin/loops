# Represents a lock object for a specific item.
#
# Usually you should use only {lock} and {unlock} methods to get
# entity locked or unlocked correspondingly. Method {locked?} could
# be used in test to verify lock status.
#
# @example Create a lock on an entity
#   LoopLock.lock(:loop => 'upload', :entity_id => 15)
#
# @example Create a lock on an entity with timeout 20 minutes
#   LoopLock.lock(:loop => 'upload', :entity_id => 15, :timeout => 20.minutes)
#
# @example Remove a lock from an entity
#   LoopLock.unlock(:loop => 'upload', :entity_id => 15)
#
# @example Verify entity locked
#   LoopLock.locked?(:loop => 'upload', :entity_id => 15)
#
class LoopLock
  @@locks = []

  # Resets all locks
  #
  # Used just for testing purpose.
  #
  def self.reset!
    @@locks = []
  end

  # Locks an entity in a specified namespace (loop).
  #
  # @param [Hash] params a hash of options.
  # @option params [String, Symbol] :loop
  #   a loop to lock an entity in. Required.
  # @option params [Integer] :entity_id
  #   ID of the entity to lock.
  # @option params [Integer] :timeout (1.year)
  #   a timeout in seconds after which lock object should be expired.
  # @return [Boolean]
  #   +true+ when locked successfully,
  #   +false+ when entity is already locked.
  #
  # @raise ArgumentError when :entity_id or :loop parameter is missing.
  #
  # @example
  #   LoopLock.lock(:loop => 'upload', :entity_id => 15, :timeout => 20.minutes)
  #
  def self.lock(params)
    raise ArgumentError, 'Not enough params for a lock' unless params[:entity_id] && params[:loop]

    # Remove all stale locks for this record
    @@locks.reject! { |lock| lock[:loop] == params[:loop] && lock[:entity_id] == params[:entity_id] && lock[:timeout_at] < Time.now }

    return false if locked?(params)

    # Create new lock
    attributes = params.dup
    timeout = attributes.delete(:timeout)
    timeout ||= 3600 * 24
    attributes[:timeout_at] = Time.now + timeout
    @@locks << attributes
    true
  end

  # Unlocks an entity in a specified namespace (loop).
  #
  # @param [Hash] params a hash of options.
  # @option params [String, Symbol] :loop
  #   a loop to lock an entity in. Required.
  # @option params [Integer] :entity_id
  #   ID of the entity to lock.
  # @return [Boolean]
  #   +true+ when unlocked successfully,
  #   +false+ when entity was not locked before.
  #
  # @raise ArgumentError when :entity_id or :loop parameter is missing.
  #
  # @example
  #   LoopLock.unlock(:loop => 'upload', :entity_id => 15)
  #
  def self.unlock(params)
    raise ArgumentError, 'Not enough params for a lock' unless params[:entity_id] && params[:loop]
    !!@@locks.reject! { |lock| lock[:loop] == params[:loop] && lock[:entity_id] == params[:entity_id] }
  end

  # Checks the state of an entity lock.
  #
  # @param [Hash] params a hash of options.
  # @option params [String, Symbol] :loop
  #   a loop to lock an entity in. Required.
  # @option params [Integer] :entity_id
  #   ID of the entity to lock.
  # @return [Boolean]
  #   +true+ when an entity is locked,
  #   +false+ when an entity is not locked.
  #
  # @raise ArgumentError when :entity_id or :loop parameter is missing.
  #
  # @example
  #   LoopLock.locked?(:loop => 'upload', :entity_id => 15)
  #
  def self.locked?(params)
    raise ArgumentError, 'Not enough params for a lock' unless params[:entity_id] && params[:loop]
    !!@@locks.index { |lock| lock[:loop] == params[:loop] && lock[:entity_id] == params[:entity_id] }
  end
end
