class CartsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ArgumentError, with: :unprocessable
  rescue_from CartService::ProductNotFoundError, with: :not_found

  # GET /cart
  def show
    return render json: empty_cart unless cart_exists?

    render json: {
      id: session[:cart_id],
      products: cart.items.values.map { |p| p.merge(id: p[:id]) },
      total_price: cart.total_price
    }
  end

  # POST /cart
  def create
    dto = CartItemDto.new(cart_item_params)
    return render_dto_error(dto) unless dto.valid?

    cart.set(dto.product_id, dto.quantity)
    show
  end

  # PATCH /cart/add_item
  def add_item
    dto = CartItemDto.new(cart_item_params)
    return render_dto_error(dto) unless dto.valid?

    cart.set(dto.product_id, dto.quantity)
    show
  end

  # DELETE /cart/:product_id
  def destroy
    cart.remove(params[:product_id])
    show
  end

  private

  def cart
    session[:cart_id] ||= SecureRandom.uuid
    @cart ||= CartService.new(session[:cart_id])
  end

  def cart_exists?
    session[:cart_id].present?
  end

  def cart_item_params
    params.require(:cart).permit(:product_id, :quantity)
  end

  def empty_cart
    { id: nil, products: [], total_price: 0 }
  end

  def render_dto_error(dto)
    render json: { errors: dto.errors.full_messages }, status: :unprocessable_entity
  end

  def not_found(e)
    render json: { error: e.message }, status: :not_found
  end

  def unprocessable(e)
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

