module Admin
  class DashboardController < BaseController
    def show
      @stats = User.dashboard_stats
      @recent_imports = UserImport.order(created_at: :desc).limit(5)
    end
  end
end
