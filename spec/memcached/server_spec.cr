require "spec"

describe Memcached::Server do
  it "sets and then gets" do
    server = Memcached::Server.new
    server.flush
    server.set("Hello", "World").should_not eq(nil)
    server.get("Hello").should eq("World")
  end

  it "sets and then gets a large value" do
    server = Memcached::Server.new
    server.flush
    value = "LargeValue" * 1000
    server.set("LargeKey", value).should_not eq(nil)
    server.get("LargeKey").should eq(value)
  end

  it "does not get non existing key" do
    server = Memcached::Server.new
    server.flush
    server.get("SomeStrangeKey").should eq(nil)
  end

  it "sets with expire" do
    server = Memcached::Server.new
    server.flush
    server.set("expires", "soon", 2)
    server.get("expires").should eq("soon")
    sleep(3)
    server.get("expires").should eq(nil)
  end

  it "gets multiple keys" do
    server = Memcached::Server.new
    server.flush
    server.set("key1", "value1")
    server.set("key3", "value3")
    response = server.get_multi(["key1", "key2", "key3", "key4", "key5"])
    response.should eq({
      "key1" => "value1",
      "key2" => nil,
      "key3" => "value3",
      "key4" => nil,
      "key5" => nil,
    })
  end

  it "handles version" do
    server = Memcached::Server.new
    server.flush
    version = server.set("vkey", "value")
    new_version = server.set("vkey", "new_value", version: version.not_nil!)
    server.get_with_version("vkey").try do |response|
      response[0].should eq("new_value")
      response[1].should eq(new_version)
    end
    raised = false
    begin
      server.set("vkey", "another_value", version: new_version.not_nil! + 1).should eq(nil)
    rescue Memcached::BadVersionException
      raised = true
    end
    raised.should eq(true)
  end

  it "deletes key" do
    server = Memcached::Server.new
    server.flush
    server.set("key", "value")
    server.get("key").should eq("value")
    server.delete("key").should eq(true)
    server.get("key").should eq(nil)
    server.delete("key").should eq(false)
  end

  it "appends" do
    server = Memcached::Server.new
    server.flush
    server.set("key", "value")
    server.get("key").should eq("value")
    server.append("key", "andmore").should eq(true)
    server.get("key").should eq("valueandmore")
  end

  it "prepends" do
    server = Memcached::Server.new
    server.flush
    server.set("pkey", "value")
    server.get("pkey").should eq("value")
    server.prepend("pkey", "somethingand").should eq(true)
    server.get("pkey").should eq("somethingandvalue")
  end

  it "touches" do
    server = Memcached::Server.new
    server.flush
    server.set("tkey", "value", 1)
    server.touch("tkey", 10).should eq(true)
    sleep(2)
    server.get("tkey").should eq("value")
  end

  it "does not touch non existing key" do
    server = Memcached::Server.new
    server.flush
    server.touch("SomeStrangeKey", 10).should eq(false)
  end

  it "flushes" do
    server = Memcached::Server.new
    server.set("fkey", "value")
    server.flush.should eq(true)
    server.get("fkey").should eq(nil)
  end

  it "flushes with delay" do
    server = Memcached::Server.new
    server.set("fdkey", "value")
    server.flush(2).should eq(true)
    server.get("fdkey").should eq("value")
    sleep(5)
    server.get("fdkey").should eq(nil)
  end

  it "increments" do
    server = Memcached::Server.new
    server.flush
    server.increment("ikey", 2, 5).should eq(5)
    server.increment("ikey", 2, 0).should eq(7)
  end

  it "decrements" do
    server = Memcached::Server.new
    server.flush
    server.decrement("dkey", 2, 5).should eq(5)
    server.decrement("dkey", 2, 0).should eq(3)
  end

  # it "fetches" do
  #   server = Memcached::Server.new
  #   server.flush

  #   result = server.fetch("key1") do
  #     "value42"
  #   end

  #   result.should eq("value42")

  #   server.get("key1").should eq("value42")
  # end

  # it "doesn't call set if the value is already present" do
  #   server = Memcached::Server.new
  #   server.flush
  #   server.set("key1", "value1")

  #   result = server.fetch("key1") do
  #     "value2"
  #   end

  #   result.should eq("value1")

  #   server.get("key1").should eq("value1")
  # end

  # it "doesn't call set if the block yields a nil" do
  #   server = Memcached::Server.new
  #   server.flush

  #   result = server.fetch("key1") do
  #     nil
  #   end

  #   result.should eq(nil)

  #   server.get("key1").should eq(nil)
  # end
end
