require 'rails_helper'

RSpec.describe "/products", type: :request do
  let(:valid_headers) { {} }

  before do
    # Limpa cache antes de cada teste
    Rails.cache.clear
  end

  describe "GET /index" do
    it "renders a successful response" do
      create(:product)

      get products_url, headers: valid_headers, as: :json

      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      product = create(:product)

      get product_url(product), headers: valid_headers, as: :json

      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      let(:valid_attributes) { attributes_for(:product) }

      it "creates a new Product" do
        expect {
          post products_url,
               params: { product: valid_attributes },
               headers: valid_headers,
               as: :json
        }.to change(Product, :count).by(1)
      end

      it "renders a JSON response with the new product" do
        post products_url,
             params: { product: valid_attributes },
             headers: valid_headers,
             as: :json

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { price: -1 } }

      it "does not create a new Product" do
        expect {
          post products_url,
               params: { product: invalid_attributes },
               as: :json
        }.not_to change(Product, :count)
      end

      it "renders a JSON response with errors" do
        post products_url,
             params: { product: invalid_attributes },
             headers: valid_headers,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include("application/json")
      end
    end
  end

  describe "PATCH /update" do
    let!(:product) { create(:product) }

    context "with valid parameters" do
      let(:new_attributes) { { name: "Another name", price: 2 } }

      it "updates the requested product" do
        patch product_url(product),
              params: { product: new_attributes },
              headers: valid_headers,
              as: :json

        product.reload

        expect(product.name).to eq("Another name")
        expect(product.price).to eq(2)
      end

      it "renders a JSON response with the product" do
        patch product_url(product),
              params: { product: new_attributes },
              headers: valid_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")
      end
    end

    context "with invalid parameters" do
      it "renders a JSON response with errors" do
        patch product_url(product),
              params: { product: { price: -1 } },
              headers: valid_headers,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include("application/json")
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:product) { create(:product) }

    it "destroys the requested product" do
      expect {
        delete product_url(product),
               headers: valid_headers,
               as: :json
      }.to change(Product, :count).by(-1)
    end
  end

  describe "cache behavior" do
    it "caches a single product on first read" do
      product = create(:product)

      expect(Rails.cache.exist?("product:#{product.id}")).to be_falsey

      get product_url(product), headers: valid_headers, as: :json

      expect(Rails.cache.exist?("product:#{product.id}")).to be_truthy
    end

    it "caches all products on first read" do
      create(:product)

      expect(Rails.cache.exist?("products:all")).to be_falsey

      get products_url, headers: valid_headers, as: :json

      expect(Rails.cache.exist?("products:all")).to be_truthy
    end

    it "invalidates the single product cache after update" do
      product = create(:product)

      get product_url(product), as: :json
      expect(Rails.cache.exist?("product:#{product.id}")).to be_truthy

      patch product_url(product),
            params: { product: { price: 10 } },
            as: :json

      expect(Rails.cache.exist?("product:#{product.id}")).to be_falsey
    end

    it "invalidates the all-products cache after creation" do
      get products_url, as: :json
      expect(Rails.cache.exist?("products:all")).to be_truthy

      create(:product)

      expect(Rails.cache.exist?("products:all")).to be_falsey
    end

    it "invalidates the all-products cache after deletion" do
      product = create(:product)

      get products_url, as: :json
      expect(Rails.cache.exist?("products:all")).to be_truthy

      delete product_url(product), as: :json

      expect(Rails.cache.exist?("products:all")).to be_falsey
    end
  end
end

