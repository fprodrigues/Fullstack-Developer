module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update destroy toggle_role]
    before_action :prevent_self_management, only: %i[destroy toggle_role]
    def index
      @users = User.order(created_at: :desc)
      @users = @users.where(role: params[:role]) if User.roles.key?(params[:role])
    end
    def show
    end
    def new
      @user = User.new
    end
    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "User created."
      else
        render :new, status: :unprocessable_entity
      end
    end
    def edit
    end
    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted.", status: :see_other
    end
    def toggle_role
      @user.update!(role: @user.admin? ? :user : :admin)
      redirect_to admin_users_path, notice: "Role updated to #{@user.role}."
    end
  private
    def set_user
      @user = User.find(params[:id])
    end

    def prevent_self_management
      return unless @user == Current.user
      redirect_to admin_users_path, alert: "You cannot change your own account here."
    end

    def user_params
      permitted = params.expect(
      user: %i[full_name email_address password password_confirmation role avatar_image]
      )
      permitted = permitted.except(:password, :password_confirmation) if permitted[:password].blank?
      permitted
    end
  end
end
