require "rails_helper"

RSpec.describe CartsController, type: :routing do
  describe 'routes' do
    it 'routes GET /cart to carts#show' do
      expect(get: '/cart').to route_to('carts#show')
    end

    it 'routes POST /cart to carts#create' do
      expect(post: '/cart').to route_to('carts#create')
    end

    it 'routes PATCH /cart/add_item to carts#add_item' do
      expect(patch: '/cart/add_item').to route_to('carts#add_item')
    end

    it 'routes DELETE /cart/:product_id to carts#destroy' do
      expect(delete: '/cart/42').to route_to('carts#destroy', product_id: '42')
    end
  end
end

