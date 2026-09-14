class ProfilesController < ApplicationController
  def show
    @user = Current.user
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    user = Current.user
    terminate_session
    user.destroy
    redirect_to root_path, notice: "Your account has been deleted."
  end
private
  def profile_params
    permitted = params.expect(
    user: %i[full_name email_address password password_confirmation avatar_image]
    )

    permitted = permitted.except(:password, :password_confirmation) if permitted[:password].blank?
    permitted
  end
end
