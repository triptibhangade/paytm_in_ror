class VerifyService
  require "uri"
  require "json"
  require "net/http"

  HTTP_VERB = {get:  Net::HTTP::Get,
               post: Net::HTTP::Post
              }

  def initialize(response)
    @json_params = response
    @paytm_response = response[:paytm_response]
    @order_id = response[:paytm_response][:ORDERID]
    @amount = response[:paytm_response][:orderAmount]
  end

  def call
    data = { body: body, head: head }
    response = call_api(:post, PaytmConfig.transaction_status_api_url, data)
    response_body = JSON[response.body]
    response_body
    end
  end

  def call_api verb, uri, data
    url = URI(uri)

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = HTTP_VERB[verb].new(url)
    request["Content-Type"] = "application/json"

    request.body = data.to_json

    response = https.request(request)
    puts response.read_body

    response
  end


  private

    def body
      {
        mid: PaytmConfig.merchant_id,
        orderId: @order_id
      }
    end

    def head
      {
        signature: signature
      }
    end

    def signature
      @signature = PaytmChecksum.new.generateSignature(body.to_json, PaytmConfig.merchant_key)
      @signature
    end
  end
