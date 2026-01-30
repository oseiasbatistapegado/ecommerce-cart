require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  let(:redis) { REDIS }
  let(:cart_id_old) { SecureRandom.uuid }
  let(:cart_id_new) { SecureRandom.uuid }

  let!(:product_old) { create(:product, price: 100.0) }
  let!(:product_new) { create(:product, price: 200.0) }

  before do
    redis.flushdb

    CartService.new(cart_id_old).set(product_old.id, 1)
    redis.zadd(
      CartService::LAST_ACTIVITY_ZSET,
      4.hours.ago.to_i,
      cart_id_old
    )

    CartService.new(cart_id_new).set(product_new.id, 1)
    redis.zadd(
      CartService::LAST_ACTIVITY_ZSET,
      1.hour.ago.to_i,
      cart_id_new
    )
  end

  it "marca apenas carrinhos antigos como abandonados" do
    MarkCartAsAbandonedJob.new.perform

    old_cart_status = redis.hget("cart:#{cart_id_old}", "status")
    new_cart_status = redis.hget("cart:#{cart_id_new}", "status")

    expect(old_cart_status).to eq("abandoned")
    expect(new_cart_status).to eq("active")
  end

  it "remove carrinhos antigos do sorted set" do
    MarkCartAsAbandonedJob.new.perform

    expect(redis.zscore(CartService::LAST_ACTIVITY_ZSET, cart_id_old)).to be_nil
    expect(redis.zscore(CartService::LAST_ACTIVITY_ZSET, cart_id_new)).not_to be_nil
  end

  it "não falha se não houver carrinhos antigos" do
    redis.del(CartService::LAST_ACTIVITY_ZSET)
    expect { MarkCartAsAbandonedJob.new.perform }.not_to raise_error
  end
end

