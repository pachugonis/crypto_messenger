class Admin::AdvertisementsController < Admin::BaseController
  before_action :set_advertisement, only: [:edit, :update, :destroy]

  def index
    @advertisements = Advertisement.ordered
  end

  def new
    @advertisement = Advertisement.new
  end

  def create
    @advertisement = Advertisement.new(advertisement_params)
    
    if @advertisement.save
      redirect_to admin_advertisements_path, notice: "Реклама успешно создана"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @advertisement.update(advertisement_params)
      redirect_to admin_advertisements_path, notice: "Реклама успешно обновлена"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @advertisement.destroy
    redirect_to admin_advertisements_path, notice: "Реклама успешно удалена"
  end

  private

  def set_advertisement
    @advertisement = Advertisement.find(params[:id])
  end

  def advertisement_params
    params.require(:advertisement).permit(
      :title, :content, :image_url, :link, :position, :active, :icon_type, :icon_color
    )
  end
end
