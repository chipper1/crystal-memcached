require "./spec_helper"
require "./memcached/*"

class ServerMock < Memcached::Server
  getter :is_set_called
  getter :is_get_called

  def initialize
    @socket = TCPSocket.new
    @is_set_called = false
    @is_get_called = true
    @storage = Hash(String, String).new
  end

  def set(key : String, value : String, expire : Number = 0, version : Number = 0) : Int64
    @is_set_called = true
    @storage[key] = value
    return 0_i64
  end

  # Get single key value from memcached.
  def get(key : String) : String?
    @is_get_called = true
    return @storage[key]
  end

  # Get single key value and its current version.
  def get_with_version(key : String) : Tuple(String, Int64)?
  end

  # Get multiple keys values from memcached.
  #
  # If a key was not found or an error occured while getting the key,
  # value for this key will be nil in the returned hash
  def get_multi(keys : Array(String)) : Hash(String, String | Nil)
  end

  # Deletes the key from memcached.
  def delete(key : String) : Bool
  end

  # Append value afrer an existing key value
  def append(key : String, value : String) : Bool
  end

  # Prepend value before an existing key value
  def prepend(key : String, value : String) : Bool
  end

  # Update key expiration time
  def touch(key : String, expire : Number) : Bool
  end

  # Remove all keys from memcached.
  #
  # Passing delay parameter postpone the removal.
  def flush(delay = 0_u32) : Bool
  end

  # Increment key value by delta.
  #
  # If key does not exist, it will be set to initial_value.
  def increment(
                key : String,
                delta : Number,
                initial_value = 0,
                expire = 0) : Int64?
  end

  # Decrement key value by delta.
  #
  # If key does not exist, it will be set to initial_value.
  def decrement(
                key : String,
                delta : Number,
                initial_value : Number = 0,
                expire : Number = 0) : Int64?
  end
end

describe Memcached do
end
