defmodule LiveXTest do
  use ExUnit.Case
  doctest LiveX

  test "greets the world" do
    assert LiveX.hello() == :world
  end
end
