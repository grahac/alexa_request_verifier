defmodule AlexaRequestVerifier.JSONRawBodyParser do
  @moduledoc """
  Parses json request body if there is a signature header copies the raw body

  Copies raw body to `:raw_body` private assign when `:copy_raw_body` 
  private assign is true
  """

  @behaviour Plug.Parsers
  alias Plug.Conn
  require Logger

  def parse(conn, "application", "json", _params, opts) do
    if Plug.Conn.get_req_header(conn, "signature") != [] do
      case Conn.read_body(conn, opts) do
        {:ok, body, conn} ->
          decoder =
            Keyword.get(opts, :json_decoder) ||
              raise ArgumentError, "JSON parser expects a :json_decoder option"

          decoded_body = decoder.decode!(body)
          {:ok, decoded_body, Plug.Conn.put_private(conn, :raw_body, body)}

        {:more, _data, conn} ->
          {:error, :too_large, conn}
      end
    else
      {:next, conn}
    end
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
