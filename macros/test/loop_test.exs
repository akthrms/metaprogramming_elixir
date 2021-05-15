defmodule LoopTest do
  use ExUnit.Case
  import Loop

  test "It is really that easy?" do
    assert Code.ensure_loaded?(Loop)
  end

  test "while/2 loops as long as the expression is truthy" do
    pid = spawn(fn -> :timer.sleep(:infinity) end)

    send(self(), :one)

    while Process.alive?(pid) do
      receive do
        :one ->
          send(self(), :two)

        :two ->
          send(self(), :three)

        :three ->
          Process.exit(pid, :kill)
          send(self(), :done)
      end
    end

    assert_receive :done
  end

  test "break/0 terminates execution" do
    send(self(), :one)

    while true do
      receive do
        :one ->
          send(self(), :two)

        :two ->
          send(self(), :three)

        :three ->
          send(self(), :done)
          break()
      end
    end

    assert_receive :done
  end
end
