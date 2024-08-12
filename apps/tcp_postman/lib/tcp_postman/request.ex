defmodule TcpPostman.Request do
  @moduledoc false

  alias Receiver.Message
  alias TcpPostman.Proto

  @type t :: %{
          attempt: non_neg_integer(),
          content: binary(),
          event_from: String.t(),
          from: pid(),
          host: list(),
          port: non_neg_integer(),
          socket: :inet.socket(),
        }

  defstruct [:host, :from, :event_from, :port, :socket, :content, attempt: 0]

  def new(event) do
    %__MODULE__{
      content: convert_event(event),
      event_from: event.from,
      host: String.to_charlist(event.host),
      port: String.to_integer(event.port),
    }
  end

  def new, do: %__MODULE__{}

  def set_socket(request, socket) do
    %{request | socket: socket}
  end

  @spec convert_event(Message.t()) :: binary()
  defp convert_event(event) do
    %Proto.Event{}
    |> Map.merge(Map.take(event, [:from, :payload]))
    |> Proto.Event.encode()
  end
end
