require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let(:cart_id) { SecureRandom.uuid }
  let(:cart_service) { CartService.new(cart_id) }

  let!(:product) { create(:product, price: 10.0) }

  before do
    # Limpa Redis antes de cada teste
    REDIS.flushdb

    # Simula sessão do carrinho
    cookies["_store_session"] = cart_id

    allow_any_instance_of(ActionDispatch::Request::Session)
      .to receive(:[]).with(:cart_id).and_return(cart_id)

    allow_any_instance_of(ActionDispatch::Request::Session)
      .to receive(:[]=).with(:cart_id, anything)
  end

  describe "GET /cart" do
    context "when cart is empty" do
      it "returns an empty cart" do
        get "/cart"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
        expect(json["total_price"]).to eq(0)
      end
    end

    context "when cart has items" do
      before { cart_service.set(product.id, 3) }

      it "returns cart with products and total price" do
        get "/cart"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(1)
        expect(json["products"][0]["id"]).to eq(product.id)
        expect(json["products"][0]["quantity"]).to eq(3)
        expect(json["total_price"]).to eq(30.0)
      end
    end
  end

  describe "POST /cart" do
    it "adds an item to the cart" do
      post "/cart",
           params: { cart: { product_id: product.id, quantity: 2 } },
           as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["products"][0]["id"]).to eq(product.id)
      expect(json["products"][0]["quantity"]).to eq(2)
      expect(json["total_price"]).to eq(20.0)
    end

    it "returns error for invalid quantity" do
      post "/cart",
           params: { cart: { product_id: product.id, quantity: -1 } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)

      json = JSON.parse(response.body)
      expect(json["errors"]).to include(/Quantity must be greater than 0/i)
    end
  end

  describe "PATCH /cart/add_item" do
    before { cart_service.set(product.id, 1) }

    it "updates quantity of existing item" do
      patch "/cart/add_item",
            params: { cart: { product_id: product.id, quantity: 2 } },
            as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["products"][0]["quantity"]).to eq(2)
      expect(json["total_price"]).to eq(20.0)
    end

    it "adds a new item if it does not exist" do
      new_product = create(:product, price: 5.0)

      patch "/cart/add_item",
            params: { cart: { product_id: new_product.id, quantity: 3 } },
            as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["products"].map { |p| p["id"] }).to include(new_product.id)
    end
  end

  describe "DELETE /cart/:product_id" do
    before { cart_service.set(product.id, 2) }

    it "removes item from cart" do
      delete "/cart/#{product.id}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["products"]).to be_empty
      expect(json["total_price"]).to eq(0)
    end

    it "returns error if product is not in cart" do
      delete "/cart/99999"

      expect(response).to have_http_status(:not_found)

      json = JSON.parse(response.body)
      expect(json["error"]).to match(/Produto 99999 não encontrado/)
    end
  end
end

