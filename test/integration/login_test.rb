require 'test_helper'

describe 'Login' do
  # Logged in students should end up at the assignments path
  it 'should succeed' do
    user = FactoryGirl::create(:user)
    user.confirm!
    visit(new_user_session_path)
    fill_in('Email', :with => user.email)
    fill_in('Password', :with => user.password)
    click_on 'Log in'

    current_path.must_equal(assignments_path)

    # I was randomly getting "email already taken" with the spec
    # syntax so I'm explicitly destroying the user when we're done
    # with it to ensure things are clean for the next test.
    user.destroy!
  end

  it 'should fail' do
    user = FactoryGirl::create(:user)
    user.confirm!
    visit(new_user_session_path)
    fill_in('Email', :with => user.email)
    fill_in('Password', :with => 'wrong')
    click_on 'Log in'

    # We should still be on the page
    current_path.must_equal(new_user_session_path)

    user.destroy!
  end
end
