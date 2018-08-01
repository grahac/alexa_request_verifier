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

  # this config list is from: https://aws.amazon.com/blogs/security/how-to-prepare-for-aws-move-to-its-own-certificate-authority/?mkt_tok=eyJpIjoiTkdaa05UVTJabUpsT0RSaSIsInQiOiI1dmhhZHpxVHRlRnZuZktWRDVGNk44czlCT21odWxDeWxrVmZSbHNoVWdcLzZsdTh3clQwNEd4N1ZEYXhrZDFjY085R0w2aVwvUTFtV3pEd0Yxa1JvalhzTlVDV1Z0SXZvc01ZQU5zbnMweW1PdWIwcXBTMU9kUjNcL29KMDhMcm9taiJ9

@root_cas [
  """
  -----BEGIN CERTIFICATE-----
  MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
  ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
  b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
  MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
  b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj
  ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM
  9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw
  IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6
  VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L
  93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm
  jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
  AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA
  A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI
  U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs
  N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv
  o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU
  5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy
  rqXRfboQnoZsG4q5WTP468SQvvG5
  -----END CERTIFICATE-----
  """,
  """
  -----BEGIN CERTIFICATE-----
  MIIFQTCCAymgAwIBAgITBmyf0pY1hp8KD+WGePhbJruKNzANBgkqhkiG9w0BAQwF
  ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
  b24gUm9vdCBDQSAyMB4XDTE1MDUyNjAwMDAwMFoXDTQwMDUyNjAwMDAwMFowOTEL
  MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
  b3QgQ0EgMjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK2Wny2cSkxK
  gXlRmeyKy2tgURO8TW0G/LAIjd0ZEGrHJgw12MBvIITplLGbhQPDW9tK6Mj4kHbZ
  W0/jTOgGNk3Mmqw9DJArktQGGWCsN0R5hYGCrVo34A3MnaZMUnbqQ523BNFQ9lXg
  1dKmSYXpN+nKfq5clU1Imj+uIFptiJXZNLhSGkOQsL9sBbm2eLfq0OQ6PBJTYv9K
  8nu+NQWpEjTj82R0Yiw9AElaKP4yRLuH3WUnAnE72kr3H9rN9yFVkE8P7K6C4Z9r
  2UXTu/Bfh+08LDmG2j/e7HJV63mjrdvdfLC6HM783k81ds8P+HgfajZRRidhW+me
  z/CiVX18JYpvL7TFz4QuK/0NURBs+18bvBt+xa47mAExkv8LV/SasrlX6avvDXbR
  8O70zoan4G7ptGmh32n2M8ZpLpcTnqWHsFcQgTfJU7O7f/aS0ZzQGPSSbtqDT6Zj
  mUyl+17vIWR6IF9sZIUVyzfpYgwLKhbcAS4y2j5L9Z469hdAlO+ekQiG+r5jqFoz
  7Mt0Q5X5bGlSNscpb/xVA1wf+5+9R+vnSUeVC06JIglJ4PVhHvG/LopyboBZ/1c6
  +XUyo05f7O0oYtlNc/LMgRdg7c3r3NunysV+Ar3yVAhU/bQtCSwXVEqY0VThUWcI
  0u1ufm8/0i2BWSlmy5A5lREedCf+3euvAgMBAAGjQjBAMA8GA1UdEwEB/wQFMAMB
  Af8wDgYDVR0PAQH/BAQDAgGGMB0GA1UdDgQWBBSwDPBMMPQFWAJI/TPlUq9LhONm
  UjANBgkqhkiG9w0BAQwFAAOCAgEAqqiAjw54o+Ci1M3m9Zh6O+oAA7CXDpO8Wqj2
  LIxyh6mx/H9z/WNxeKWHWc8w4Q0QshNabYL1auaAn6AFC2jkR2vHat+2/XcycuUY
  +gn0oJMsXdKMdYV2ZZAMA3m3MSNjrXiDCYZohMr/+c8mmpJ5581LxedhpxfL86kS
  k5Nrp+gvU5LEYFiwzAJRGFuFjWJZY7attN6a+yb3ACfAXVU3dJnJUH/jWS5E4ywl
  7uxMMne0nxrpS10gxdr9HIcWxkPo1LsmmkVwXqkLN1PiRnsn/eBG8om3zEK2yygm
  btmlyTrIQRNg91CMFa6ybRoVGld45pIq2WWQgj9sAq+uEjonljYE1x2igGOpm/Hl
  urR8FLBOybEfdF849lHqm/osohHUqS0nGkWxr7JOcQ3AWEbWaQbLU8uz/mtBzUF+
  fUwPfHJ5elnNXkoOrJupmHN5fLT0zLm4BwyydFy4x2+IoZCn9Kr5v2c69BoVYh63
  n749sSmvZ6ES8lgQGVMDMBu4Gon2nL2XA46jCfMdiyHxtN/kHNGfZQIG6lzWE7OE
  76KlXIx3KadowGuuQNKotOrN8I1LOJwZmhsoVLiJkO/KdYE+HvJkJMcYr07/R54H
  9jVlpNMKVv/1F2Rs76giJUmTtt8AF9pYfl3uxRuw0dFfIRDH+fO6AgonB8Xx1sfT
  4PsJYGw=
  -----END CERTIFICATE-----
  """,
  """
  -----BEGIN CERTIFICATE-----
  MIIBtjCCAVugAwIBAgITBmyf1XSXNmY/Owua2eiedgPySjAKBggqhkjOPQQDAjA5
  MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6b24g
  Um9vdCBDQSAzMB4XDTE1MDUyNjAwMDAwMFoXDTQwMDUyNjAwMDAwMFowOTELMAkG
  A1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJvb3Qg
  Q0EgMzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABCmXp8ZBf8ANm+gBG1bG8lKl
  ui2yEujSLtf6ycXYqm0fc4E7O5hrOXwzpcVOho6AF2hiRVd9RFgdszflZwjrZt6j
  QjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgGGMB0GA1UdDgQWBBSr
  ttvXBp43rDCGB5Fwx5zEGbF4wDAKBggqhkjOPQQDAgNJADBGAiEA4IWSoxe3jfkr
  BqWTrBqYaGFy+uGh0PsceGCmQ5nFuMQCIQCcAu/xlJyzlvnrxir4tiz+OpAUFteM
  YyRIHN8wfdVoOw==
  -----END CERTIFICATE-----
  """,
  """
  -----BEGIN CERTIFICATE-----
  MIIB8jCCAXigAwIBAgITBmyf18G7EEwpQ+Vxe3ssyBrBDjAKBggqhkjOPQQDAzA5
  MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6b24g
  Um9vdCBDQSA0MB4XDTE1MDUyNjAwMDAwMFoXDTQwMDUyNjAwMDAwMFowOTELMAkG
  A1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJvb3Qg
  Q0EgNDB2MBAGByqGSM49AgEGBSuBBAAiA2IABNKrijdPo1MN/sGKe0uoe0ZLY7Bi
  9i0b2whxIdIA6GO9mif78DluXeo9pcmBqqNbIJhFXRbb/egQbeOc4OO9X4Ri83Bk
  M6DLJC9wuoihKqB1+IGuYgbEgds5bimwHvouXKNCMEAwDwYDVR0TAQH/BAUwAwEB
  /zAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0OBBYEFNPsxzplbszh2naaVvuc84ZtV+WB
  MAoGCCqGSM49BAMDA2gAMGUCMDqLIfG9fhGt0O9Yli/W651+kI0rz2ZVwyzjKKlw
  CkcO8DdZEv8tmZQoTipPNU0zWgIxAOp1AE47xDqUEpHJWEadIRNyp4iciuRMStuW
  1KyLa2tJElMzrdfkviT8tQp21KW8EA==
  -----END CERTIFICATE-----
  """,
  """
  -----BEGIN CERTIFICATE-----
  MIIEDzCCAvegAwIBAgIBADANBgkqhkiG9w0BAQUFADBoMQswCQYDVQQGEwJVUzEl
  MCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEyMDAGA1UECxMp
  U3RhcmZpZWxkIENsYXNzIDIgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMDQw
  NjI5MTczOTE2WhcNMzQwNjI5MTczOTE2WjBoMQswCQYDVQQGEwJVUzElMCMGA1UE
  ChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEyMDAGA1UECxMpU3RhcmZp
  ZWxkIENsYXNzIDIgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggEgMA0GCSqGSIb3
  DQEBAQUAA4IBDQAwggEIAoIBAQC3Msj+6XGmBIWtDBFk385N78gDGIc/oav7PKaf
  8MOh2tTYbitTkPskpD6E8J7oX+zlJ0T1KKY/e97gKvDIr1MvnsoFAZMej2YcOadN
  +lq2cwQlZut3f+dZxkqZJRRU6ybH838Z1TBwj6+wRir/resp7defqgSHo9T5iaU0
  X9tDkYI22WY8sbi5gv2cOj4QyDvvBmVmepsZGD3/cVE8MC5fvj13c7JdBmzDI1aa
  K4UmkhynArPkPw2vCHmCuDY96pzTNbO8acr1zJ3o/WSNF4Azbl5KXZnJHoe0nRrA
  1W4TNSNe35tfPe/W93bC6j67eA0cQmdrBNj41tpvi/JEoAGrAgEDo4HFMIHCMB0G
  A1UdDgQWBBS/X7fRzt0fhvRbVazc1xDCDqmI5zCBkgYDVR0jBIGKMIGHgBS/X7fR
  zt0fhvRbVazc1xDCDqmI56FspGowaDELMAkGA1UEBhMCVVMxJTAjBgNVBAoTHFN0
  YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xMjAwBgNVBAsTKVN0YXJmaWVsZCBD
  bGFzcyAyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5ggEAMAwGA1UdEwQFMAMBAf8w
  DQYJKoZIhvcNAQEFBQADggEBAAWdP4id0ckaVaGsafPzWdqbAYcaT1epoXkJKtv3
  L7IezMdeatiDh6GX70k1PncGQVhiv45YuApnP+yz3SFmH8lU+nLMPUxA2IGvd56D
  eruix/U0F47ZEUD0/CwqTRV/p2JdLiXTAAsgGh1o+Re49L2L7ShZ3U0WixeDyLJl
  xy16paq8U4Zt3VekyvggQQto8PT7dL5WXXp59fkdheMtlb71cZBDzI0fmgAKhynp
  VSJYACPq4xJDKVtHCN2MQWplBqjlIapBtJUhlbl90TSrE9atvNziPTnNvT51cKEY
  WQPJIrSPnNVeKtelttQKbfi3QBFGmh95DmK/D5fs4C8fF5Q=
  -----END CERTIFICATE-----
  """
]

  import Plug.Conn

  alias Plug.Conn

  require Logger
 @amazon_echo_dns "echo-api.amazon.com"
 @sig_header  "signature"
 @sig_chain_header "signaturecertchainurl"

  def init(opts), do: opts


  def call(conn, _opts) do

   case conn.private[:alexa_verify_test_disable] do
     true ->
      conn
     _ ->

    conn = conn
    |> get_validated_cert
    |> verify_time
    |> verify_signature

    if conn.private[:alexa_verify_error] do
      Logger.debug("alexa_request_verifier: #{conn.private[:alexa_verify_error]}")
      conn
        |> send_resp(401, conn.private[:alexa_verify_error])
        |> halt
    else
      conn
      end
   end
  end

  def get_validated_cert(conn) do
     case Plug.Conn.get_req_header(conn, @sig_chain_header) do

      [] ->  Conn.put_private(conn, :alexa_verify_error, "no request parameter named #{@sig_chain_header}" )
      [cert_url] -> cert_url = cert_url

        cert = ConCache.get(:cert_signature_cache, cert_url)
        if is_nil(cert) do
          cert = fetch_cert(cert_url)
        case validate_cert(cert) do

        {:ok, _} ->
            Logger.debug("alexa_request_verifier: setting cache for #{cert_url}")
            ConCache.put(:cert_signature_cache, cert_url, cert)

            Conn.put_private(conn,:signing_cert, cert)

        {:error, reason} ->
            Logger.debug("alexa_request_verifier: got error -  #{reason}")
            Conn.put_private(conn, :alexa_verify_error, reason )

          end
        else
          Conn.put_private(conn,:signing_cert, cert)
        end
    end
end



@doc """
  takes a string and confirms URL is in scheme https, has a s3.amazonaws.com host, is port 443 and has a path starting with /echo.api/

"""

  def is_correct_alexa_url?(url) when is_binary(url) do
      is_correct_alexa_url?(URI.parse(url))

  end


  def is_correct_alexa_url?(url) when is_nil(url) do
      false
  end


  def is_correct_alexa_url?(%URI{port: 443, host: "s3.amazonaws.com", scheme: "https", path: "/echo.api/" <> _extra}) do
      true
  end

  def is_correct_alexa_url?(_everything_else) do
      false
  end


  def fetch_cert(url) do
    if(!is_correct_alexa_url?(url)) do
      {:error, "invalid sig chain url"}
    else

      {:ok, resp} = :httpc.request(:get, {String.to_charlist(url), []}, [], [body_format: :binary])
      {_, _headers, certificate_chain_bin} = resp
      cert_chain = :public_key.pem_decode(certificate_chain_bin)
      Enum.map(cert_chain,
        fn {_, bin, _} -> bin
      end)

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
    # {:ok, resp} = :httpc.request(:get, {'https://certs.secureserver.net/repository/sf-class2-root.crt', []}, [], [body_format: :binary])
    # {_, _headers, root_cert_bin} = resp
    #   {:ok, root_cert_bin} = :file.read_file("./auth_root.pem")
    found_ca = @root_cas
      |> Enum.find(fn root_ca ->
        case validate_cert_by_binary(root_ca, cert) do
          {:ok, _} -> true
          {:error, _} -> false
        end
      end)
    case found_ca do
      nil -> {:error, :no_root_ca_found}
      _ -> {:ok, cert}
    end

  end

  def validate_cert_by_binary(root_cert_bin, cert) do
    [{_, root_cer, _}] = :public_key.pem_decode(root_cert_bin)
    case :public_key.pkix_path_validation(root_cer, Enum.reverse(cert),
          [{:verify_fun, {&__MODULE__.verify_fun/3, {}}}]) do
      {:ok, {_public_key_info, _policy_tree}} ->
        {:ok, cert}
      {:error, {:bad_cert, reason}} ->
        {:error, reason}
    end
  end

  def validate_cert(err = {:error, _reason}) do
      err
  end

  def validate_cert(cert)  do
      validate_cert_chain(cert)
      |> validate_cert_domain
 end

  def validate_cert_domain(error = {:error, _reason}) do
    error
  end

  def validate_cert_domain({:ok, cert}) do
    [first|_tail] = cert
    if :public_key.pkix_verify_hostname(first, [{:dns_id, @amazon_echo_dns}])  do
      {:ok, cert}
    else
      {:error, "invalid DNS"}
    end

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
    min = 150 # minimum number of seconds
   NaiveDateTime.diff(NaiveDateTime.utc_now(),
     datetime, :second) <= min
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
          Conn.put_private(conn, :alexa_verify_error, "invalid timestamp" )
    end
     conn
  end

  @doc """
    Assuming :raw_body, :signing_cert, and signature header, it will verify the signature
  """


  def verify_signature(conn) do
    case conn.private[:signing_cert] do
     nil->
      Conn.put_private(conn, :alexa_verify_error, "invalid certificate" )
     _ ->
      verify_signature_with_valid_cert(conn)
    end

  end

  def verify_signature_with_valid_cert(conn) do

   message = conn.private[:raw_body]
   case Plug.Conn.get_req_header(conn, @sig_header) do
    []  ->   Conn.put_private(conn, :alexa_verify_error, "no signature" )
    [signature] ->
      {:ok, signature} = Base.decode64(signature)
      [first|_tail] = conn.private[:signing_cert]
      decoded = :public_key.pkix_decode_cert(first,:otp)
      public_key_der = decoded |> elem(1) |> elem(7) |> elem(2)

      if(!is_nil(public_key_der) and :public_key.verify(message, :sha, signature, public_key_der)) do
        Logger.debug("alexa_request_verifier: Signature of Alexa request is valid for this message.")
        conn
      else
        Conn.put_private(conn, :alexa_verify_error, "signature did not match" )
      end
   end
 end
end
