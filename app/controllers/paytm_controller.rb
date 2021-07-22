class PaytmController < ApplicationController
  before_action :check_amount, only: [:paytm_initiate_transaction]

  def paytm_initiate_transaction
    render json: InitService.new(params, order_id).call
  end

  def paytm_verify_transaction
    render json: VerifyService.new(params).call
  end

  private

  def check_amount
    render :json => {'errors' => ['Amount is required']}, :status => :not_found unless params[:amount].present?
  end

  def order_id
    "#{Time.now.to_i}#{SecureRandom.hex(2)}"
  end
end
