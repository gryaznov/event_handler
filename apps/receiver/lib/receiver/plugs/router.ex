defmodule Receiver.Plugs.Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug :match

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug Receiver.Plugs.MessageValidator, path: "mailbox"

  plug :dispatch

  # routes
  post "/mailbox", do: handle_mail(conn)

  match _, do: send_resp(conn, 404, "Unknown address")

  # helpers
  @spec handle_mail(Plug.Conn.t()) :: Plug.Conn.t()
  defp handle_mail(%Plug.Conn{body_params: message} = conn) do
    case Receiver.pass(message) do
      {:ok, success} -> send_resp(conn, 200, success)
      _ -> send_resp(conn, 422, "Sorry, something went wrong.")
    end
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{reason: %Plug.Parsers.UnsupportedMediaTypeError{}}) do
    send_resp(conn, conn.status, "Bad Request. Please use 'application/json'")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{
        reason: %Receiver.Plugs.MessageValidator.InvalidMessageError{} = reason
      }) do
    send_resp(conn, reason.plug_status, "Bad Request. #{reason.message}")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, _) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end
