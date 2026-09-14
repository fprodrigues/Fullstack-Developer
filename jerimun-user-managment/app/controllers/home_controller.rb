class HomeController < ApplicationController
  allow_unauthenticated_access only: :show
  def show
    redirect_to(Current.user.admin? ? admin_root_path : profile_path) if authenticated?
  end
end
