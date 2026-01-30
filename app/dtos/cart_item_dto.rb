class CartItemDto
  include ActiveModel::Model

  attr_accessor :product_id, :quantity

  validates :product_id, presence: true, numericality: { only_integer: true }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
end

