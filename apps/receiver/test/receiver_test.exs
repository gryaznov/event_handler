defmodule ReceiverTest do
  use ExUnit.Case, async: true

  @message %{
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

  describe "pass/1" do
    test "message successfully processed" do
      assert {:ok, "Message received."} = Receiver.pass(@message)
    end
  end
end
