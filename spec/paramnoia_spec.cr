require "./spec_helper"

enum TestEnum
  Foo
  Bar
  Baz
end

class TestParams
  include Paramnoia::Params

  getter string : String
  getter optional_string : String?
  getter string_with_default : String = "foo"
  getter int : Int32
  getter optional_int : Int32?
  getter int_with_default : Int32 = 1
  getter enum : TestEnum
  getter optional_enum : TestEnum?
  getter enum_with_default : TestEnum = TestEnum::Foo
  getter array : Array(String)
  getter optional_array : Array(String)?
  getter array_with_default : Array(String) = %w[foo bar baz]
  getter hash : Hash(String, Int32)
  getter optional_hash : Hash(String, Int32)?
  getter hash_with_default : Hash(String, Int32) = {"foo" => 1}
  getter tuple : Tuple(String, Int32, Float64)
  getter optional_tuple : Tuple(String, Int32, Float64)?
  getter tuple_with_default : Tuple(String, Int32, Float64) = {"foo", 1, 1.2}
  getter boolean : Bool
  getter optional_boolean : Bool?
  getter boolean_with_default : Bool = false

  getter nested : Bar

  class Bar
    include Paramnoia::Params

    getter foo : Int32?
    getter bar : Int16 = 2
    getter baz : Array(String)
  end
end

describe Paramnoia do
  context "with all fields set correctly" do
    it "works" do
      http_params = HTTP::Params.build do |p|
        p.add("string", "string_value")
        p.add("optional_string", "optional_string_value")
        p.add("string_with_default", "string_with_default_value")
        p.add("int", "1")
        p.add("optional_int", "2")
        p.add("int_with_default", "3")
        p.add("enum", "Foo")
        p.add("optional_enum", "Bar")
        p.add("enum_with_default", "Baz")
        p.add("array[]", "foo")
        p.add("array[]", "bar")
        p.add("array[]", "baz")
        p.add("optional_array[]", "foo")
        p.add("optional_array[]", "bar")
        p.add("array_with_default[]", "foo")
        p.add("hash[foo]", "1")
        p.add("hash[bar]", "2")
        p.add("optional_hash[foo]", "3")
        p.add("optional_hash[bar]", "4")
        p.add("hash_with_default[foo]", "5")
        p.add("tuple[]", "foo")
        p.add("tuple[]", "2")
        p.add("tuple[]", "3.5")
        p.add("boolean", "1")
        p.add("optional_boolean", "false")
        p.add("boolean_with_default", "true")
        p.add("nested[foo]", "1")
        p.add("nested[bar]", "3")
        p.add("nested[baz][]", "foo")
        p.add("nested[baz][]", "bar")
      end

      params = TestParams.from_urlencoded(http_params)
      params.string.should eq("string_value")
      params.optional_string.should eq("optional_string_value")
      params.string_with_default.should eq("string_with_default_value")
      params.int.should eq(1)
      params.optional_int.should eq(2)
      params.int_with_default.should eq(3)
      params.enum.should eq(TestEnum::Foo)
      params.optional_enum.should eq(TestEnum::Bar)
      params.enum_with_default.should eq(TestEnum::Baz)
      params.array.should eq(%w[foo bar baz])
      params.optional_array.should eq(%w[foo bar])
      params.array_with_default.should eq(%w[foo])
      params.hash.should eq({ "foo" => 1, "bar" => 2 })
      params.optional_hash.should eq({ "foo" => 3, "bar" => 4 })
      params.hash_with_default.should eq({ "foo" => 5 })
      params.tuple.should eq({ "foo", 2, 3.5 })
      params.boolean.should eq(true)
      params.optional_boolean.should eq(false)
      params.boolean_with_default.should eq(true)
      params.nested.foo.should eq(1)
      params.nested.bar.should eq(3)
      params.nested.baz.should eq(%w[foo bar])
    end
  end

  context "with nilable fields unset" do
    it "works" do
      http_params = HTTP::Params.build do |p|
        p.add("string", "string_value")
        p.add("string_with_default", "string_with_default_value")
        p.add("int", "1")
        p.add("int_with_default", "3")
        p.add("enum", "Foo")
        p.add("enum_with_default", "Baz")
        p.add("array[]", "foo")
        p.add("array[]", "bar")
        p.add("array[]", "baz")
        p.add("array_with_default[]", "foo")
        p.add("hash[foo]", "1")
        p.add("hash[bar]", "2")
        p.add("hash_with_default[foo]", "5")
        p.add("tuple[]", "foo")
        p.add("tuple[]", "2")
        p.add("tuple[]", "3.5")
        p.add("boolean", "1")
        p.add("boolean_with_default", "true")
        p.add("nested[bar]", "3")
        p.add("nested[baz][]", "foo")
        p.add("nested[baz][]", "bar")
      end

      params = TestParams.from_urlencoded(http_params)
      params.optional_string.should be_nil
      params.optional_int.should be_nil
      params.optional_enum.should be_nil
      params.optional_array.should be_nil
      params.optional_hash.should be_nil
      params.optional_tuple.should be_nil
      params.optional_boolean.should be_nil
      params.nested.foo.should be_nil
    end

    context "with fields having default values unset" do
      it "works" do
        http_params = HTTP::Params.build do |p|
          p.add("string", "string_value")
          p.add("int", "1")
          p.add("enum", "Foo")
          p.add("array[]", "foo")
          p.add("array[]", "bar")
          p.add("array[]", "baz")
          p.add("hash[foo]", "1")
          p.add("hash[bar]", "2")
          p.add("tuple[]", "foo")
          p.add("tuple[]", "2")
          p.add("tuple[]", "3.5")
          p.add("boolean", "1")
          p.add("nested[baz][]", "foo")
          p.add("nested[baz][]", "bar")
        end

        params = TestParams.from_urlencoded(http_params)
        params.string_with_default.should eq("foo")
        params.int_with_default.should eq(1)
        params.enum_with_default.should eq(TestEnum::Foo)
        params.array_with_default.should eq(%w[foo bar baz])
        params.hash_with_default.should eq({ "foo" => 1 })
        params.tuple_with_default.should eq({ "foo", 1, 1.2 })
        params.boolean_with_default.should eq(false)
        params.nested.bar.should eq(2)
      end
    end
  end
end
