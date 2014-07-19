require 'test_helper'

class HomeTest < ActionDispatch::IntegrationTest
  test 'Home page for guests must work' do
    get '/'
    assert_response :success
  end
end
