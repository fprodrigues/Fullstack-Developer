module SessionTestHelper
  def sign_in_as(user, password: "password123")
    post session_url, params: { email_address: user.email_address, password: password }
  end
  def sign_out
    delete session_url
  end
  def sign_in_through_ui(user, password: "password123")
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_on "Sign in"
  end
end
