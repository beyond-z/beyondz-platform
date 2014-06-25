require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  test 'Login successfully' do
    user = FactoryGirl::create(:user)
    user.confirm!
    post '/users/sign_in', :user => {:email => user.email, :password => user.password }
    assert_response :redirect # successful login redirects the user
  end

  test 'Login failure when not confirmed' do
    user = FactoryGirl::create(:user)
    post '/users/sign_in', :user => {:email => user.email, :password => user.password }
    assert_equal 'You have to confirm your account before continuing.', flash[:alert]
  end

  test 'Login failure' do
    user = FactoryGirl::create(:user)
    post '/users/sign_in', :user => {:email => user.email, :password => 'wrong' }
    # Log in failure means they have to try again, so we should still be here
    assert_equal '/users/sign_in', path
    assert_equal 'Invalid email or password.', flash[:alert]
  end

end
