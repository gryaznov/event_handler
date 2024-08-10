defmodule Plugs.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Receiver.Plugs.Router

  describe "invalid requests" do
    test "invalid route returns 404" do
      conn = :post |> conn("/something-weird", "") |> Router.call([])

      assert_received {:plug_conn, :sent}
      assert {404, _, "Unknown address"} = sent_resp(conn)
    end

    test "valid route, invalid verb return 404" do
      conn = :get |> conn("/mailbox", "") |> Router.call([])

      assert_received {:plug_conn, :sent}
      assert {404, _, "Unknown address"} = sent_resp(conn)
    end

    test "valid route, invalid type return 415" do
      conn = :post |> conn("/mailbox", "") |> put_req_header("content-type", "text/html")

      assert_raise Plug.Parsers.UnsupportedMediaTypeError,
                   "unsupported media type text/html",
                   fn -> Router.call(conn, []) end

      assert_received {:plug_conn, :sent}
      assert {415, _, "Bad Request. Please use 'application/json'"} = sent_resp(conn)
    end

    test "valid route, invalid body return 400" do
      conn =
        :post
        |> conn("/mailbox", Jason.encode!(%{something: "weird"}))
        |> put_req_header("content-type", "application/json")

      assert_raise Receiver.Plugs.MessageValidator.InvalidMessageError,
                   "Invalid message.",
                   fn -> Router.call(conn, []) end

      assert_received {:plug_conn, :sent}
      assert {400, _, "Bad Request. Invalid message."} = sent_resp(conn)
    end
  end

  describe "valid requests" do
    message = %{
      "host" => "196.222.8.186",
      "port" => "49150",
      "timestamp" => "1723185202",
      "event_id" => "6a740f4c-a686-452d-9880-fdfcacc3af86",
      "from" => "Test Testerson",
      "payload" => %{
        "payload_type" => "text",
        "text" => "Succes!"
      }
    }

    conn =
      :post
      |> conn("/mailbox", Jason.encode!(message))
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

    assert_received {:plug_conn, :sent}
    assert {200, _, "Message received."} = sent_resp(conn)
  end
end
