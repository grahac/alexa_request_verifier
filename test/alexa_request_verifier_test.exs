defmodule AlexaRequestVerifierTest do
  use ExUnit.Case
  doctest AlexaRequestVerifier

  test "load, verified cert and test caching " do 
    cert_url = "https://s3.amazonaws.com/echo.api/echo-api-cert-4.pem"
    conn = %Plug.Conn{}
    |> Plug.Conn.put_req_header("signaturecertchainurl", cert_url )
    |> AlexaRequestVerifier.get_validated_cert
    cert = conn.private[:signing_cert]
    assert ConCache.get(:cert_signature_cache, cert_url) == cert
    assert AlexaRequestVerifier.get_validated_cert(conn).private[:signing_cert] == cert
  end

  test "load, bad cert and test no caching " do 
    cert_url = "https://s3.amazonaws.com/echo.api/echo-api-cert.pem"
    conn = %Plug.Conn{}
    |> Plug.Conn.put_req_header("signaturecertchainurl", cert_url)
    |> AlexaRequestVerifier.get_validated_cert
    assert (conn.private[:alexa_verify_error])
    assert ConCache.get(:cert_signature_cache, cert_url) == nil


  end


  test "load no cert request " do 
    conn = %Plug.Conn{}
    |> AlexaRequestVerifier.get_validated_cert
    assert String.contains?(conn.private[:alexa_verify_error], "no request parameter")
  end




  test "is_datetime_valid tests " do 
    refute AlexaRequestVerifier.is_datetime_valid?(nil)
    refute AlexaRequestVerifier.is_datetime_valid?("")
    refute AlexaRequestVerifier.is_datetime_valid?("2016-03-20T19:03:53Z")
    refute AlexaRequestVerifier.is_datetime_valid?("2017-03-20T19:03:53Z")
    assert AlexaRequestVerifier.is_datetime_valid?(DateTime.to_iso8601(DateTime.utc_now()))
  end

 test "valid amazonaws cert url tests" do
   refute AlexaRequestVerifier.is_correct_alexa_url?(nil)
   refute AlexaRequestVerifier.is_correct_alexa_url?("http://www.alexa.com")
   refute AlexaRequestVerifier.is_correct_alexa_url?("hello world")
   refute AlexaRequestVerifier.is_correct_alexa_url?("http://s3.amazonaws.com/echo.api/echo-api-cert.pem")
   refute AlexaRequestVerifier.is_correct_alexa_url?("https://s4.amazonaws.com/bad_bad.api/echo-api-cert.pem")
   refute AlexaRequestVerifier.is_correct_alexa_url?("https://s3.amazonaws.com:12345/echo.api/echo-api-cert.pem")
   refute AlexaRequestVerifier.is_correct_alexa_url?("ftp://s3.amazonaws.com/echo.api/echo-api-cert.pem")
   assert AlexaRequestVerifier.is_correct_alexa_url?("https://s3.amazonaws.com:443/echo.api/echo-api-cert.pem")
   assert AlexaRequestVerifier.is_correct_alexa_url?("https://s3.amazonaws.com/echo.api/echo-api-cert.pem")
   assert AlexaRequestVerifier.is_correct_alexa_url?("https://s3.amazonaws.com/echo.api/echo-api-cert4.pem")
   assert AlexaRequestVerifier.is_correct_alexa_url?("https://s3.amazonaws.com/echo.api/../echo.api/echo-api-cert.pem")
   

 end

  
 test "test_mode disables authentication checking" do
    cert_url = "https://www.foobar.com"
    conn = %Plug.Conn{}
    |> Plug.Conn.put_private(:alexa_verify_test_disable, true)
    |> Plug.Conn.put_req_header("signaturecertchainurl", cert_url)
    |> AlexaRequestVerifier.call(%{})
    refute conn.private[:alexa_verify_error]
  end


end
