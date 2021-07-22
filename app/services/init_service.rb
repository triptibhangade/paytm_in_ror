class InitService
  require "uri"
  require "json"
  require "net/http"

  HTTP_VERB = {get:  Net::HTTP::Get,
               post: Net::HTTP::Post
              }

  def initialize(response, order_id)
    @response = response
    @order_id = order_id
  end

  def call
    Rails.logger.info "======= Before Calling Initiate Transaction API, Order Id: #{@order_id} ======="
    uri = "#{PaytmConfig.initiate_transaction_api_url}?mid=#{PaytmConfig.merchant_id}&orderId=%{order_txn_id}" % { order_txn_id: @order_id }
    data = { head: head, body: body }
    response = call_api(:post, uri, data)
    Rails.logger.info "======= After Calling Initiate Transaction API, Order Id: #{@order_id} ======="
    response = { MID: PaytmConfig.merchant_id, order_id: @order_id, callbackURL: "#{PaytmConfig.callback_url}?ORDER_ID=#{@order_id}", amount: @response[:amount], paytm_response: response } if response.present?
    Rails.logger.info "======= Final Response of Initiate Transaction API: #{response} ======="
    response
  end

  def call_api verb, uri, data
    begin
      url = URI(uri)

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = HTTP_VERB[verb].new(url)
      request["Content-Type"] = "application/json"

      request.body = data.to_json

      response = https.request(request)
      response_body = JSON[response.body]

      if response.code == "200" and response_body['body']['resultInfo']['resultMsg'] == 'Success'
        Rails.logger.info "======= Success in Paytm #{uri} api: #{response_body} ======="
        response_body
      else
        Rails.logger.error "======= Error in Paytm #{uri} api: #{response.read_body} ======="
        response_body
      end
    rescue Exception => ke
      Rails.logger.error "======= Error in Paytm #{uri} api due to: #{e.message} ======="
    end
    response_body
  end

  private
    def body
      Rails.logger.info "======= In Body, Order Id: #{@order_id} ======="
      body = {
        requestType: 'Payment',
        mid: PaytmConfig.merchant_id,
        websiteName: PaytmConfig.website_name,
        orderId: @order_id,
        txnAmount: txn_amount,
        userInfo: user_info,
        callbackUrl: "#{PaytmConfig.callback_url}?ORDER_ID=#{@order_id}"
      }
      body[:enablePaymentMode] = payment_mode if @response[:mode].present?&&@response[:channels].present?
      body
    end

    def head
      {
        version: 'v1',
        channelId: PaytmConfig.channel_id,
        requestTimestamp: Time.zone.now.to_i.to_s,
        signature: signature
      }
    end

    def user_info
      {
        custId: "1"
      }
    end

    def txn_amount
      {
        value: txn_value,
        currency: "INR"
      }
    end

    def txn_value
      @response[:amount].to_s
    end

    def payment_mode
      [
        {
          mode: @response[:mode],
          channels: @response[:channels]
        }
      ]
    end

    def signature
      @signature = PaytmChecksum.new.generateSignature(body.to_json, PaytmConfig.merchant_key)
      @signature
    end

    def success
      'S'
    end
end
