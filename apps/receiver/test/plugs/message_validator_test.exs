defmodule Plugs.MessageValidatorTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Receiver.Plugs.MessageValidator, as: Validator

  @init_opts Validator.init(path: "mailbox")

  @valid_message %{
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

  describe "passes" do
    test "when a path does not require validation" do
      assert %Plug.Conn{} = conn(:post, "/", "") |> Validator.call(@init_opts)
    end

    test "when a verb does not require validation" do
      assert %Plug.Conn{} = conn(:get, "/mailbox", "") |> Validator.call(@init_opts)
    end

    test "when a message is valid" do
      assert %Plug.Conn{} =
               conn(:post, "/mailbox", @valid_message)
               |> Validator.call(@init_opts)
    end
  end

  describe "fails" do
    test "when all required keys are missing in the message" do
      assert_raise Receiver.Plugs.MessageValidator.InvalidMessageError,
                   "Invalid message.",
                   fn ->
                     Validator.call(conn(:post, "/mailbox", %{}), @init_opts)
                   end
    end

    test "when some keys are missing in the message" do
      invalid_message = Map.drop(@valid_message, ["host", "from"])

      assert_raise Receiver.Plugs.MessageValidator.InvalidMessageError,
                   "Invalid message.",
                   fn ->
                     Validator.call(conn(:post, "/mailbox", invalid_message), @init_opts)
                   end
    end

    test "when unknown keys are present in the message" do
      invalid_message = Map.put_new(@valid_message, "details", "garbage")

      assert_raise Receiver.Plugs.MessageValidator.InvalidMessageError,
                   "Invalid message.",
                   fn ->
                     Validator.call(conn(:post, "/mailbox", invalid_message), @init_opts)
                   end
    end

    test "when required keys do not have values" do
      invalid_message = Map.put(@valid_message, "host", "")

      assert_raise Receiver.Plugs.MessageValidator.InvalidMessageError,
                   "Invalid message.",
                   fn ->
                     Validator.call(conn(:post, "/mailbox", invalid_message), @init_opts)
                   end
    end
  end
end
