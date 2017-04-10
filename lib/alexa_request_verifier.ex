defmodule AlexaRequestVerifier do
  @moduledoc """
  Documentation for AlexaRequestVerifier.
  """


  import Plug.Conn

  alias Plug.Conn

  require Logger
 @amazon_echo_dns "echo-api.amazon.com"
 @sig_header  "signature"
@sig_chain_header "signaturecertchainurl"

  def init(opts), do: opts


  def call(conn, _opts) do
      
    Logger.info(inspect(conn))
  
    conn = conn  
    |> get_validated_cert
    |> verify_time
    |> verify_signature
      
    if conn.private[:alexa_verify_error] do 
      Logger.error("alexa_verify_error: #{conn.private[:alexa_verify_error]}")
      conn
        |> send_resp(401, conn.private[:alexa_verify_error])
        |> halt
    else
      conn
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
            Logger.debug("setting cache for #{cert_url}")
            ConCache.put(:cert_signature_cache, cert_url, cert)

            Conn.put_private(conn,:signing_cert, cert)
              
        {:error, reason} ->
            Logger.error("got error: #{reason}")
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
   
  end


  def is_correct_alexa_url?(url =%URI{port: 443, host: "s3.amazonaws.com", scheme: "https", path: "/echo.api/" <> _extra}) do
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
  def verify_fun(_, {:bad_cert, reason}, state) do
    {:fail, reason}
  end
  def verify_fun(_, {:revoked, _}, state) do
    {:fail, :revoked}
  end

  def verify_fun(_cert, event, state) do
    {:unknown, state}
  end




@doc """
  Validates the cert checks for hostname, checks that the cert has a valid key, etc... 

"""

  def validate_cert_chain(cert) do 
 

    {:ok, resp} = :httpc.request(:get, {'https://www.symantec.com/content/dam/symantec/docs/other-resources/verisign-class-3-public-primary-certification-authority-g5-en.pem', []}, [], [body_format: :binary])
    {_, _headers, root_cert_bin} = resp

 #   {:ok, root_cert_bin} = :file.read_file("./auth_root.pem")
    [{_, root_cer, _}] = :public_key.pem_decode(root_cert_bin)

    case :public_key.pkix_path_validation(root_cer, Enum.reverse(cert),
          [{:verify_fun, {&__MODULE__.verify_fun/3, {}}}]) do
      {:ok, {public_key_info, _policy_tree}} ->
        


      # IO.inspect public_key_info
        {:ok, cert}
      {:error, {:bad_cert, reason}} ->
      #  IO.puts "validation failed with bad cert"
      #  IO.inspect reason
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

  def validate_cert_domain(error = {:error, reason}) do 
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

   message = conn.private[:raw_body]
   [signature] = Plug.Conn.get_req_header(conn, @sig_header)
   [first|_tail] = conn.private[:signing_cert]
   
   if(:public_key.verify(message, :sha, signature, first)) do
    conn
   else
    Conn.put_private(conn, :alexa_verify_error, "signature did not match" )

   end

    
  end

 

end