defmodule TcpPostman.Request do
  @moduledoc false

  @type t :: %{
          host: list(),
          port: non_neg_integer(),
          socket: :inet.socket(),
          content: String.t() | nil,
          from: pid(),
          event_from: String.t(),
          attempt: non_neg_integer()
        }

  defstruct [:host, :from, :event_from, :port, :socket, :content, attempt: 0]

  def new(host: host, port: port) do
    %__MODULE__{host: host, port: port}
  end

  def new(), do: %__MODULE__{}

  def set_socket(request, socket) do
    %{request | socket: socket}
  end
end
