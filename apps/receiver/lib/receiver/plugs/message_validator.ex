defmodule Receiver.Plugs.MessageValidator do
  defmodule InvalidMessageError do
    @moduledoc false

    defexception message: "Invalid message.", plug_status: 400
  end

  @moduledoc """
  Performs various validations of an incoming message.
  Raises an error if the message is somehow invalid.
  """
  @required_message_keys ~w(host port timestamp event_id from payload)
  @required_valuable_keys ~w(host port from payload)

  def init(opts), do: opts

  def call(%Plug.Conn{body_params: message, path_info: [path], method: "POST"} = conn, path: path) do
    valid = validate_keys(message) and validate_required_values(message)
    unless valid, do: raise(InvalidMessageError)

    conn
  end

  def call(conn, _), do: conn

  @spec validate_keys(map :: map()) :: boolean()
  defp validate_keys(map) do
    map |> Map.keys() |> Enum.sort() == Enum.sort(@required_message_keys)
  end

  @spec validate_required_values(map :: map()) :: boolean()
  defp validate_required_values(map) do
    Enum.all?(
      map |> Map.take(@required_valuable_keys) |> Map.values(),
      &valuable?/1
    )
  end

  @spec valuable?(value :: any()) :: boolean()
  defp valuable?(""), do: false
  defp valuable?(nil), do: false
  defp valuable?(" "), do: false
  defp valuable?(_), do: true
end
