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

  test "known good cert signature" do
    signature = "a/T+f9igAMdTgJl+kwwSFb5SKmlkRAAdZx6dMSQeb8eWBB/ZpZ8Fxlbq2SEmZIt8gLNvh/11IrWqtlIwhT9atZRM7ETnpybzsF6QBGlyRkVSi19/kalgiNMOFJ4ohANpeDeLMwUpZ5EpbuTz0G/oR3UpjFB05NoIeVuW0GT8JZD8k0DLJ6zYC2FsoA5UyJv/rabdrJlpRR+M3Hx/SE9XfHHrTOtJ9HJnKZBbHjqnrOD2MogWHmStwAeOjFRuXnO4fR+B1E6ax3A93nv8uLlapIQ9kgV3qOEJCFi74xE+MLczXRa/rLHQB1EnG3qa1pGQBCBoNQGEuPtIC1eAiM42Sg=="
    chain_url = "https://s3.amazonaws.com/echo.api/echo-api-cert-6-ats.pem"
    cert = AlexaRequestVerifier.fetch_cert("https://s3.amazonaws.com/echo.api/echo-api-cert-6-ats.pem")
    {:ok, _} = AlexaRequestVerifier.validate_cert_chain(cert)
  end


  test "load bad cache test " do
    cert_url = "https://s3.amazonaws.com/echo.api/echo-api-cert.pem"
    conn = %Plug.Conn{}
    |> Plug.Conn.put_req_header("signaturecertchainurl", cert_url)
    |> Plug.Conn.put_req_header("signature", "M4Xq8WmUHjaR4Fgj9HUheoOUkZf4tkc5koBtkBq/nCmh4X6EiimBXWa7p+kHoMx9noTdytGSUREaxYofTne1CzYOW0wxb9x6Jhor6lMwHAr4cY+aR1AEOkWrjsP94bewRr1/CxYNl7kGcj4+QjbEa/7dL19BNmLiufMLZDdRFsZSzlfXpPaAspsoStqVc/qc26tj5R9wtB0sTS4wbFc4eyCPFaCZocq1gmjfR3YQXupuD7J3slrz54SxukNmL/M1CIoZ8lOXjS82XLkKjsrzXdY5ePk8XsEDjNWkFSLbqzBzGBqzWx4M913uDA6gPx5tFKeoP8FgpV+BHKDf3d4gmQ==")
    |> Plug.Conn.put_private(:raw_body, "foobar" )
    |> AlexaRequestVerifier.verify_signature
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
   assert AlexaRequestVerifier.is_correct_alexa_url?("https://s3.amazonaws.com/echo.api/echo-api-cert-6-ats.pem")


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
