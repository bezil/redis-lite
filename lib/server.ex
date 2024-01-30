defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use Application

  def start(_type, _args) do
    Supervisor.start_link([
      {Task, fn -> Server.listen() end},
      {Storage, %{}}
    ], strategy: :one_for_one)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    IO.puts("Listening for incoming connections here!")

    serve()
  end

  def serve() do
    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    accept_connections(socket)
  end

  def accept_connections(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn(fn -> handle_client(client) end)
    accept_connections(socket)
  end

  def handle_client(client) do
    {:ok, data} = :gen_tcp.recv(client, 0)

    list = data |> String.trim() |> String.split("\r\n")

    cond do
      String.contains?(data, "echo") == true ->
        handle_echo_cammand(client, list)
      String.contains?(data, "px") == true ->
        [_,_,_command,_,key,_,value,_,_px,_,px] = list
        handle_set_with_timer_cammand(client, key, value, px)
      String.contains?(data, "set") == true ->
        [_,_,_command,_,key,_,value] = list
        handle_set_cammand(client, key, value)
      String.contains?(data, "get") == true ->
        [_,_,_command,_,key] = list
        handle_get_cammand(client, key)
      String.contains?(data, "ping") == true ->
        :gen_tcp.send(client, "+PONG\r\n")
    end

    handle_client(client)
  end

  def handle_echo_cammand(client, list) do
    :gen_tcp.send(client, "+#{hd(Enum.reverse(list))}\r\n")
  end

  def handle_set_cammand(client, key, value) do
    Storage.set(key, value)
    :gen_tcp.send(client, "+OK\r\n")
  end

  def handle_set_with_timer_cammand(client, key, value, px) do
    px = String.to_integer(px)
    Storage.set(key, value, timer: px)
    :gen_tcp.send(client, "+OK\r\n")
  end

  def handle_get_cammand(client, key) do
    value = Storage.get(key)
    case value == nil do
      true -> :gen_tcp.send(client, "$#{-1}\r\n")
      false -> :gen_tcp.send(client, "$#{byte_size(value)}\r\n#{value}\r\n")
    end
  end
end
