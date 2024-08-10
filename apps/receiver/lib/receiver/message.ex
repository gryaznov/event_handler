defmodule Receiver.Message do
  @moduledoc false

  @type message_payload() :: %{
          payload_type: String.t(),
          text: String.t()
        }

  @type t() :: %{
          host: String.t(),
          port: String.t(),
          timestamp: String.t(),
          event_id: String.t(),
          from: String.t(),
          payload: message_payload()
        }

  defstruct [:host, :port, :timestamp, :event_id, :from, :payload]

  @spec new(map()) :: __MODULE__.t()
  def new(data), do: Map.merge(%__MODULE__{}, data)
end
