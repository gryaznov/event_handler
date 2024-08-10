defmodule Receiver do
  @moduledoc """
  Receives an incoming JSON message, and passes it to an end receiver.
  """
  alias Receiver.Message

  @doc """
  Accepts a message and passes it to a recipient.
  Since neither we, nor client care about what the receipient does with the message,
  the pass happens in a separate, unlinked process.
  """
  @spec pass(message :: Message.message()) :: {:ok, String.t()}
  def pass(message) do
    message
    |> atomize_message_keys()
    |> pass_to_recipient()

    {:ok, "Message received."}
  end

  @spec atomize_message_keys(message :: Message.message()) :: Message.message()
  defp atomize_message_keys(message) do
    message
    |> Jason.encode!()
    |> Jason.decode!(keys: :atoms)
  end

  @spec pass_to_recipient(message :: Message.message()) :: {:ok, pid()}
  defp pass_to_recipient(message) do
    Task.start(TcpPostman, :send_event, [TcpPostman, message])
  end
end
