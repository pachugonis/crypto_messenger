class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :update, :destroy, :lock, :unlock, :make_admin, :remove_admin ]

  def index
    @users = User.order(created_at: :desc)

    if params[:q].present?
      @users = @users.where("username ILIKE ? OR email_address ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    if params[:role].present?
      @users = @users.where(role: params[:role])
    end

    @users = @users.page(params[:page]).per(20) if @users.respond_to?(:page)
  end

  def show
    @rooms = @user.rooms.order(created_at: :desc).limit(10)
    @messages_count = @user.messages.count
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: t("admin.users.updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: t("admin.users.cannot_delete_self")
      return
    end

    @user.destroy
    redirect_to admin_users_path, notice: t("admin.users.deleted")
  end

  def lock
    @user.lock!
    redirect_to admin_user_path(@user), notice: t("admin.users.locked")
  end

  def unlock
    @user.unlock!
    redirect_to admin_user_path(@user), notice: t("admin.users.unlocked")
  end

  def make_admin
    @user.admin!
    redirect_to admin_user_path(@user), notice: t("admin.users.made_admin")
  end

  def remove_admin
    if @user == current_user
      redirect_to admin_user_path(@user), alert: t("admin.users.cannot_demote_self")
      return
    end

    @user.user!
    redirect_to admin_user_path(@user), notice: t("admin.users.removed_admin")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:username, :email_address)
  end
end
