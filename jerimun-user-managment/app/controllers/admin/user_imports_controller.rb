module Admin
  class UserImportsController < BaseController
    def index
      @user_imports = UserImport.includes(:created_by).order(created_at: :desc)
    end
    def new
      @user_import = UserImport.new
    end
    def create
      @user_import = UserImport.new(user_import_params)
      @user_import.created_by = Current.user
      if @user_import.save
        UserImportJob.perform_later(@user_import.id)
        redirect_to admin_user_import_path(@user_import),
        notice: "Import queued. Progress updates live below."
      else
        render :new, status: :unprocessable_entity
      end
    end
    def show
      @user_import = UserImport.find(params[:id])
    end
  private
    def user_import_params
      params.expect(user_import: [ :file ])
    end
  end
end
