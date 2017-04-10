defmodule AlexaRequestVerifierTest do
  use ExUnit.Case
  doctest AlexaRequestVerifier

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "load, verified cert and test caching " do 
    cert_url = "https://s3.amazonaws.com/echo.api/echo-api-cert-4.pem"
    conn = %Plug.Conn{}
    conn = Plug.Conn.put_req_header(conn, "signaturecertchainurl", cert_url )
    conn = AlexaRequestVerifier.get_validated_cert(conn)
    assert ConCache.get(:cert_signature_cache, cert_url) == conn.private[:signing_cert]
    cert = AlexaRequestVerifier.get_validated_cert(conn)
  end

  test "load, bad cert and test no caching " do 
    cert_url = "https://s3.amazonaws.com/echo.api/echo-api-cert.pem"
    conn = %Plug.Conn{}
    conn = Plug.Conn.put_req_header(conn, "signaturecertchainurl", cert_url)
    conn = AlexaRequestVerifier.get_validated_cert(conn)
    assert (conn.private[:alexa_verify_error])
    assert ConCache.get(:cert_signature_cache, cert_url) == nil


  end


  test "load no cert request " do 
    conn = %Plug.Conn{}
    conn = AlexaRequestVerifier.get_validated_cert(conn)
    assert String.contains?(conn.private[:alexa_verify_error], "no request parameter")
  end

  test "test " do
    assert true 
  end


  test "verify message" do
    assert true 
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

  



end
