# This class is a client for memcached storage
#
# ** Usage **
# ```crystal
# # Require package
# require "memcached"
#
# # Create client instance
# client = Memcached::Client.new
#
# # Execute commands
# client.set("key", "value")
# client.set("another_key", "another_value")
# client.get("key")                        # "value"
# client.get_multi(["key", "another_key"]) # { "key" => "value", "another_key" => "another_value"}
# client.delete("key")
# ```
module Memcached
  @servers : Server
  @hash_function : String -> Int32

  class Client
    def initialize(servers : Array(Tuple(String, Int32)) = [{"localhost", 11211}])
      @servers = Array(Memcached::Server).new
      servers.each do |server|
        @servers.push(Memcached::Server.new(server[0], server[1]))
      end
      @hash_function = ->(key : String) { key.hash % @servers.size }
    end

    def initialize(servers : Array(Memcached::Server), hash_function : (String -> Int32))
      @servers = servers
      @hash_function = hash_function
    end

    # Set key - value pair in memcached.
    #
    # By default the key is set without expiration time.
    # If you want to set TTL for the key,
    # pass TTL in seconds as *expire* parameter
    # If *version* parameter is provided, it will be compared to existing key
    # version in memcached. If versions differ, *Memcached::BadVersionException*
    # will be raised.
    def set(key : String, value : String, expire : Number = 0, version : Number = 0) : Int64
      get_server_for_key(key).set(key, value, expire, version)
    end

    # Get single key value from memcached.
    def get(key : String) : String?
      get_server_for_key(key).get(key)
    end

    # Get single key value and its current version.
    def get_with_version(key : String) : Tuple(String, Int64)?
      get_server_for_key(key).get_with_version(key)
    end

    # Get multiple keys values from memcached.
    #
    # If a key was not found or an error occured while getting the key,
    # value for this key will be nil in the returned hash
    def get_multi(keys : Array(String)) : Hash(String, String | Nil)
      result = Hash(String, String | Nil).new
      keys_by_server = Hash(Memcached::Server, Array(String)).new
      keys.each do |key|
        server = get_server_for_key(key)
        if !keys_by_server[server]
          keys_by_server[server] = Array(String).new
        end
        keys_by_server[server].push(key)
      end
      channel = Channel(Hash(String, String | Nil)).new
      keys_by_server.each do |server, keys|
        spawn do
          channel.send(server.get_multi(keys))
        end
      end
      keys_by_server.keys.size.times do
        result.merge!(channel.receive)
      end
      result
    end

    # Fetch the value associated with the key.
    # If a value is found, then it is returned.
    # If a value is not found, the block will be invoked and its return value
    # (given that it is not nil) will be written to the cache.
    def fetch(key : String, expire : Number = 0, version : Number = 0) : String?
      value = get_server_for_key(key).get(key)
      if !value && (value = yield)
        get_server_for_key(key).set(key, value, expire, version)
      end
      value
    end

    # Deletes the key from memcached.
    def delete(key : String) : Bool
      get_server_for_key(key).delete(key)
    end

    # Append value afrer an existing key value
    def append(key : String, value : String) : Bool
      get_server_for_key(key).append(key, value)
    end

    # Prepend value before an existing key value
    def prepend(key : String, value : String) : Bool
      get_server_for_key(key).prepend(key, value)
    end

    # Update key expiration time
    def touch(key : String, expire : Number) : Bool
      get_server_for_key(key).touch(key, expire)
    end

    # Remove all keys from memcached.
    #
    # Passing delay parameter postpone the removal.
    def flush(delay = 0_u32) : Bool
      channel = Channel(Bool).new
      @servers.each do |server|
        spawn do
          channel.send(server.flush(delay))
        end
      end
      result = true
      @servers.size.times do
        result = result && channel.receive
      end
      return result
    end

    # Increment key value by delta.
    #
    # If key does not exist, it will be set to initial_value.
    def increment(
                  key : String,
                  delta : Number,
                  initial_value = 0,
                  expire = 0) : Int64?
      get_server_for_key(key).increment(
        key,
        delta,
        initial_value,
        expire
      )
    end

    # Decrement key value by delta.
    #
    # If key does not exist, it will be set to initial_value.
    def decrement(
                  key : String,
                  delta : Number,
                  initial_value : Number = 0,
                  expire : Number = 0) : Int64?
      get_server_for_key(key).decrement(
        key,
        delta,
        initial_value,
        expire
      )
    end

    private def get_server_for_key(key : String) : Memcached::Server
      server_number = @hash_function.call(key)
      @servers[server_number]
    end
  end
end
