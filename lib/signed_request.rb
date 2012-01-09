require 'openssl'
require 'base64'
require 'json'

module SignedRequest
  # Facebook's base64 algorithm is a special "URL" version of the algorithm.
  def base64_url_decode(str)
    str += '=' * (4 - str.length.modulo(4))
    Base64.decode64(str.tr('-_','+/'))
  end

  # Verifies that the signed_request parameter is from Facebook. An
  # exception is thrown if it is not. A hash with the data from the
  # request is returned.
  def parse_signed_request(params, app_secret_key)
    raise Exception.new("No signed request parameter!") unless params['signed_request']
    # signed_request is a . delimited string, first part is the signature
    # base64 encoded, second part is the JSON object base64 encoded
    parts = params['signed_request'].split(".")
    json_str = base64_url_decode(parts[1])
    json_obj = JSON.parse(json_str)
    if json_obj['algorithm'] && json_obj['algorithm'] != 'HMAC-SHA256'
      raise Exception.new("Unsupported signature algorithm - #{json_obj['algorithm']}")
    end
    # This is our calculation of the secret key
    expected = OpenSSL::HMAC.digest('sha256',app_secret_key,parts[1])
    actual = base64_url_decode(parts[0])
    if expected != actual
      raise Exception.new("Validation of request from Facebook failed!")
    end
    # This should contain issued_at at a minimum. If this came from a user 
    # that has installed your app, it will contain user_id, oauth_token,
    # expires, app_data, page, profile_id
    json_obj
  end
end  

