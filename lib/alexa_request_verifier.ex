defmodule AlexaRequestVerifier do
  @moduledoc """
      AlexaRequestVerifier verifies an Amazon Alexa Skills request to a Pheonix server.

      To add the request, you will need to make 4 changes:

      1. mix.exs - the package can be installed by adding `alexa_request_verifier` to your list of dependencies in `mix.exs`:


          def deps do
            [{:alexa_request_verifier, "~> 0.1.3"}]
          end

      2. You will need to add AlexaRequestVerifier as an application in your mix.js


            applications: [..., :alexa_request_verifier]


      3.  You will need to modify your endpoint.ex file by adding the JSONRawBody Parser as follows:

            parsers: [AlexaRequestVerifier.JSONRawBodyParser, :urlencoded, :multipart, :json],

      The parser is needed to collect the raw body of the request as that is needed to verify the signature.

      4. You will need to add the verifier plug to your pipeline in your router.ex file

        pipeline :alexa_api do
            plug :accepts, ["json"]
            plug AlexaRequestVerifier
        end
  """

  alias Plug.Conn

  require Logger
  @amazon_echo_dns "echo-api.amazon.com"
  @sig_header "signature"
  @sig_chain_header "signaturecertchainurl"

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.private[:alexa_verify_test_disable] do
      true ->
        conn

      _ ->
        conn =
          conn
          |> get_validated_cert
          |> verify_time
          |> verify_signature

        if conn.private[:alexa_verify_error] do
          Logger.debug("alexa_request_verifier: #{conn.private[:alexa_verify_error]}")

          conn
          |> Conn.send_resp(401, conn.private[:alexa_verify_error])
          |> Conn.halt()
        else
          conn
        end
    end
  end

  def get_validated_cert(conn) do
    case Conn.get_req_header(conn, @sig_chain_header) do
      [] ->
        Conn.put_private(
          conn,
          :alexa_verify_error,
          "no request parameter named #{@sig_chain_header}"
        )

      [cert_url] ->
        cert = ConCache.get(:cert_signature_cache, cert_url)

        if is_nil(cert) do
          cert = fetch_cert(cert_url)

          case validate_cert(cert) do
            {:ok, _} ->
              ConCache.put(:cert_signature_cache, cert_url, cert)
              Conn.put_private(conn, :signing_cert, cert)

            {:error, reason} ->
              Conn.put_private(conn, :alexa_verify_error, reason)
          end
        else
          Conn.put_private(conn, :signing_cert, cert)
        end
    end
  end

  @doc """
  Takes a string and confirms URL is in scheme https, has a s3.amazonaws.com host, is port 443 and has a path starting with /echo.api/
  """
  def is_correct_alexa_url?(url) when is_binary(url) do
    is_correct_alexa_url?(URI.parse(url))
  end

  def is_correct_alexa_url?(url) when is_nil(url) do
    false
  end

  def is_correct_alexa_url?(%URI{
        port: 443,
        host: "s3.amazonaws.com",
        scheme: "https",
        path: "/echo.api/" <> _extra
      }) do
    true
  end

  def is_correct_alexa_url?(_everything_else) do
    false
  end

  def fetch_cert(url) do
    if(!is_correct_alexa_url?(url)) do
      {:error, "invalid sig chain url"}
    else
      {:ok, resp} = :httpc.request(:get, {String.to_charlist(url), []}, [], body_format: :binary)
      {_, _headers, certificate_chain_bin} = resp
      cert_chain = :public_key.pem_decode(certificate_chain_bin)

      Enum.map(
        cert_chain,
        fn {_, bin, _} -> bin end
      )
    end
  end

  def verify_fun(_, {:extension, _}, state) do
    {:unknown, state}
  end

  def verify_fun(_, {:bad_cert, reason}, _state) do
    {:fail, reason}
  end

  def verify_fun(_, {:revoked, _}, _state) do
    {:fail, :revoked}
  end

  def verify_fun(_cert, _event, state) do
    {:unknown, state}
  end

  @doc """
    Validates the cert checks for hostname, checks that the cert has a valid key, etc...
    loop through the configured root CA's
  """

  def validate_cert_chain(cert) do
    :certifi.cacerts()
    |> Enum.reduce(
      {:error, :no_root_ca_found},
      fn
        _, {:ok, _} = acc ->
          acc

        root_cert_bin, {:error, _} ->
          validate_cert_by_binary(root_cert_bin, cert)
      end
    )
  end

  def validate_cert_by_binary(root_cer, cert) do
    case :public_key.pkix_path_validation(root_cer, Enum.reverse(cert), [
           {:verify_fun,
            {&:ssl_verify_hostname.verify_fun/3, [{:check_hostname, '#{@amazon_echo_dns}'}]}}
         ]) do
      {:ok, {_public_key_info, _policy_tree}} ->
        {:ok, cert}

      {:error, {:bad_cert, reason}} ->
        {:error, reason}
    end
  end

  def validate_cert(err = {:error, _reason}) do
    err
  end

  def validate_cert(cert) do
    validate_cert_chain(cert)
  end

  def is_datetime_valid?(datetime_string) when is_binary(datetime_string) do
    case NaiveDateTime.from_iso8601(datetime_string) do
      {:ok, datetime} ->
        is_datetime_valid?(datetime)

      {:error, _reason} ->
        false
    end
  end

  def is_datetime_valid?(datetime = %NaiveDateTime{}) do
    # minimum number of seconds
    min = 150
    NaiveDateTime.diff(NaiveDateTime.utc_now(), datetime, :second) <= min
  end

  def is_datetime_valid?(datetime) when is_nil(datetime) do
    false
  end

  @doc """
    given a Plug.Conn that has a valid Alexa request request/timestamp, it will confirm the timestamp is valid
  """

  def verify_time(conn) do
    params = conn.body_params
    timestamp = params["request"]["timestamp"]

    case is_datetime_valid?(timestamp) do
      true ->
        conn

      false ->
        Conn.put_private(conn, :alexa_verify_error, "invalid timestamp")
    end

    conn
  end

  @doc """
    Assuming :raw_body, :signing_cert, and signature header, it will verify the signature
  """

  def verify_signature(conn) do
    case conn.private[:signing_cert] do
      nil ->
        Conn.put_private(conn, :alexa_verify_error, "invalid certificate")

      _ ->
        verify_signature_with_valid_cert(conn)
    end
  end

  def verify_signature_with_valid_cert(conn) do
    message = conn.private[:raw_body]

    case Conn.get_req_header(conn, @sig_header) do
      [] ->
        Conn.put_private(conn, :alexa_verify_error, "no signature")

      [signature] ->
        {:ok, signature} = Base.decode64(signature)
        [first | _tail] = conn.private[:signing_cert]
        decoded = :public_key.pkix_decode_cert(first, :otp)
        public_key_der = decoded |> elem(1) |> elem(7) |> elem(2)

        if(
          !is_nil(public_key_der) and :public_key.verify(message, :sha, signature, public_key_der)
        ) do
          Logger.debug(
            "alexa_request_verifier: Signature of Alexa request is valid for this message."
          )

          conn
        else
          Conn.put_private(conn, :alexa_verify_error, "signature did not match")
        end
    end
  end
end
