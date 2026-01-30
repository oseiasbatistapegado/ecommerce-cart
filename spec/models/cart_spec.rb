# spec/models/cart_spec.rb
require 'rails_helper'

RSpec.describe Cart, type: :model do
  describe 'defaults' do
    it 'has status active by default' do
      cart = Cart.new
      expect(cart.status).to eq('active')
      expect(cart.active?).to be_truthy
    end
  end

  describe 'enum status' do
    it 'allows status active and abandoned' do
      cart = Cart.new(status: 'active')
      expect(cart.active?).to be_truthy
      cart.status = 'abandoned'
      expect(cart.abandoned?).to be_truthy
    end
  end

  describe '#mark_abandoned!' do
    let(:cart) { Cart.new }

    it 'changes status to abandoned' do
      expect { cart.mark_abandoned! }.to change { cart.status }.from('active').to('abandoned')
    end

    it 'sets abandoned_at when marking abandoned' do
      cart.mark_abandoned!
      expect(cart.abandoned_at).not_to be_nil
      expect(cart.abandoned_at).to be_within(1.second).of(Time.current)
    end

    it 'does nothing if already abandoned' do
      cart.status = 'abandoned'
      cart.abandoned_at = 1.hour.ago
      expect { cart.mark_abandoned! }.not_to change { cart.abandoned_at }
    end
  end

  describe '#active?' do
    it 'returns true if status is active' do
      cart = Cart.new(status: 'active')
      expect(cart.active?).to be_truthy
    end

    it 'returns false if status is abandoned' do
      cart = Cart.new(status: 'abandoned')
      expect(cart.active?).to be_falsey
    end
  end
end

