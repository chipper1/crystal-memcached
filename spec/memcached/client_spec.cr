require "spec"

def build_client
  servers = Array(Memcached::Server).new
  server0 = ServerMock.new
  server1 = ServerMock.new
  server2 = ServerMock.new
  servers.push(server0, server1, server2)
  hash_function = ->(key : String) {
    case key
    when "key0"
      return 0
    when "key1"
      return 1
    when "key2"
      return 2
    else
      return 0
    end
  }
  return Tuple.new(Memcached::Client.new(servers, hash_function), [server0, server1, server2])
end

describe Memcached::Client do
  it "sets and then gets" do
    client, servers = build_client
    client.set("key0", "World").should_not eq(nil)
    servers[0].is_set_called.should eq(true)
    servers[1].is_set_called.should eq(false)
    servers[1].is_set_called.should eq(false)
    client.get("key0").should eq("World")
  end
end
