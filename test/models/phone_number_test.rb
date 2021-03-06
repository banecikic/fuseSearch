require 'test_helper'

class PhoneNumberTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  INVALID_PHONE_NUMBER = "+3816453"
  VALID_PHONE_NUMBERS = ["+381640347000", "381640347000", "+381(64)034-7000", "+381 64 034 70 00"]

  def setup
    @phone_number = phone_numbers(:one)
    @token = @phone_number.get_token
    Twilio::REST::Messages.any_instance.stubs(:create)
  end

  test 'phone number is valid' do
    assert @phone_number.valid?
  end

  test 'number must be present' do
    @phone_number.number = " " * 5
    assert_not @phone_number.valid?
  end

  test 'number have to be valid' do
    @phone_number.number = INVALID_PHONE_NUMBER
    assert_not @phone_number.valid?
  end

  test 'number have to be mobile' do
    @phone_number.number = "+38134342480"
    assert_not @phone_number.valid?
  end

  test 'number have to be unique' do
    phone_number_dup = @phone_number.dup
    @phone_number.save
    assert_not phone_number_dup.valid?

    #test taken method - should return true
    assert phone_number_dup.taken?
  end

  test 'number have to be reformatted in canonical form' do

    # this will call validation callbacks and reformat number in canonical form
    @phone_number.number = VALID_PHONE_NUMBERS[0]
    @phone_number.valid?
    number = @phone_number.number

    VALID_PHONE_NUMBERS.each do |valid|
      @phone_number.number = valid
      assert @phone_number.valid? # valid? will also trigger validation callbacks
      assert_equal number, @phone_number.number
    end
  end

  test 'it generates secret token 8 digits long' do
    assert_equal 8, @token.length
  end

  test 'it generates secret token with only alpha chars' do
    refute @token.match(/[A-Za-z]/)
  end

  test 'it does not generate same token twice' do
    refute_equal @token, @phone_number.get_token
  end

  test 'it does not strip leading zeros from token' do
    assert_equal '00045678', @phone_number.get_token(0.00045678)
  end

  test 'sending token' do

    token = @phone_number.get_token

    Twilio::REST::Messages.any_instance.expects(:create).with(
        has_entries(
            body: "#{token} is your secret code",
            from: PhoneNumber::TWILIO_PHONE_NUMBER,
            to: @phone_number.number
        )
    )

    @phone_number.send_token(token)
  end

  test 'authentication via token' do
    token = @phone_number.get_token
    @phone_number.send_token(token)
    assert_equal PhoneNumber::TOKEN_VALID, @phone_number.authenticate(token)
  end

  test 'authentication fails with wrong token' do
    token = @phone_number.get_token
    @phone_number.send_token(token)
    assert_equal PhoneNumber::TOKEN_INVALID, @phone_number.authenticate(@phone_number.get_token)
  end

  test 'authentication fails if token expired' do
    token = @phone_number.get_token
    @phone_number.send_token(token)
    @phone_number.update_attribute(:token_sent_at, 2.hours.ago)
    assert_equal PhoneNumber::TOKEN_EXPIRED, @phone_number.authenticate(token)
  end



end
