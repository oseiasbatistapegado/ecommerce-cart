class CartService
  TTL = 7.days.to_i
  PRODUCTS_KEY = "products:ids"
  LAST_ACTIVITY_ZSET = "carts:last_activity"

  class ProductNotFoundError < StandardError; end

  def initialize(cart_id)
    @cart_id  = cart_id
    @cart_key = "cart:#{cart_id}"
    @redis    = REDIS
  end

    def items
    data = @redis.hgetall(@cart_key)
              .select { |k,_| k.start_with?("items:") }

    data.transform_keys { |k| k.delete_prefix("items:").to_i }
        .transform_values { |v| Marshal.load(v) }
  end

  def set(product_id, quantity)
    raise ArgumentError, "Quantity must be > 0" if quantity <= 0
    product = Product.find(product_id)
    @redis.watch(@cart_key) do
      current_data = @redis.hget(@cart_key, "items:#{product_id}")
      current_quantity = current_data ? Marshal.load(current_data)[:quantity] : 0
      delta_total = (quantity - current_quantity) * product.price.to_f

      @redis.multi do |multi|
        multi.sadd(PRODUCTS_KEY, product_id)
        multi.hset(@cart_key, "items:#{product_id}", Marshal.dump({
          id: product_id,
          name: product.name,
          quantity: quantity,
          unit_price: product.price.to_f,
          total_price: quantity * product.price.to_f
        }))
        multi.hset(@cart_key, "status", "active", "last_updated_at", Time.current.to_i)
        multi.hdel(@cart_key, "abandoned_at")
        multi.zadd(LAST_ACTIVITY_ZSET, Time.current.to_i, @cart_id)
        multi.hincrbyfloat(@cart_key, "total_price", delta_total)
        multi.expire(@cart_key, TTL)
      end
    end
  end

  def total_price
    @redis.hget(@cart_key, "total_price")&.to_f || 0.0
  end

  def remove(product_id)
    unless @redis.hexists(@cart_key, "items:#{product_id}")
      raise ProductNotFoundError, "Produto #{product_id} não encontrado no carrinho"
    end

    @redis.watch(@cart_key) do
      item_data = Marshal.load(@redis.hget(@cart_key, "items:#{product_id}"))
      delta_total = -item_data[:total_price].to_f

      @redis.multi do |multi|
        multi.hdel(@cart_key, "items:#{product_id}")
        multi.hset(@cart_key, "status", "active", "last_updated_at", Time.current.to_i)
        multi.hdel(@cart_key, "abandoned_at")
        multi.zadd(LAST_ACTIVITY_ZSET, Time.current.to_i, @cart_id)
        multi.hincrbyfloat(@cart_key, "total_price", delta_total)
        multi.expire(@cart_key, TTL)
      end
    end
  end

  def mark_abandoned!
    if @redis.exists(@cart_key)
      abandoned_at = Time.current.to_i
      @redis.hset(@cart_key, "status", "abandoned", "abandoned_at", abandoned_at)
      @redis.expire(@cart_key, TTL)
      @redis.zrem(LAST_ACTIVITY_ZSET, @cart_id)
    end
  end

  # private

  # def eval_with_fallback(action, product_id, quantity)
  #   evalsha(action, product_id, quantity)
  # rescue Redis::CommandError => e
  #   raise unless e.message.include?("PRODUCT_NOT_FOUND")
  #
  #   unless Product.exists?(product_id)
  #     raise ActiveRecord::RecordNotFound, "Product #{product_id} not found"
  #   end
  #
  #   @redis.sadd(PRODUCTS_KEY, product_id)
  #   evalsha(action, product_id, quantity)
  # end
  #
  # def evalsha(action, product_id = nil, quantity = nil)
  #   @redis.evalsha(script_sha(action),
  #     keys: [@cart_key, PRODUCTS_KEY, LAST_ACTIVITY_ZSET],
  #     argv: [product_id, quantity, TTL, @cart_id]
  #   )
  # end
  #
  # def script_sha(action)
  #   @script_sha[action] ||= @redis.script(:load, LUA[action])
  # end
  #
  # LUA = {
  #   set: <<~LUA,
  #     local cart_key      = KEYS[1]
  #     local products_key  = KEYS[2]
  #     local activity_zset = KEYS[3]
  #
  #     local product_id = ARGV[1]
  #     local quantity   = tonumber(ARGV[2])
  #     local ttl        = tonumber(ARGV[3])
  #     local cart_id    = ARGV[4]
  #
  #     if not quantity or quantity <= 0 then
  #       return { err = "INVALID_QUANTITY" }
  #     end
  #
  #     if redis.call("SISMEMBER", products_key, product_id) == 0 then
  #       return { err = "PRODUCT_NOT_FOUND" }
  #     end
  #
  #     local now = redis.call("TIME")[1]
  #     local item_key = "items:" .. product_id
  #
  #     redis.call("HSET", cart_key, item_key, quantity)
  #     redis.call("HSET", cart_key,
  #       "last_updated_at", now,
  #       "status", "active"
  #     )
  #     redis.call("HDEL", cart_key, "abandoned_at")
  #     redis.call("ZADD", activity_zset, now, cart_id)
  #     redis.call("EXPIRE", cart_key, ttl)
  #
  #     return quantity
  #   LUA
  #
  #   remove: <<~LUA,
  #     local cart_key      = KEYS[1]
  #     local activity_zset = KEYS[3]
  #
  #     local product_id = ARGV[1]
  #     local ttl        = tonumber(ARGV[3])
  #     local cart_id    = ARGV[4]
  #     local item_key   = "items:" .. product_id
  #
  #     if redis.call("HEXISTS", cart_key, item_key) == 0 then
  #       return 0
  #     end
  #
  #     local now = redis.call("TIME")[1]
  #
  #     redis.call("HDEL", cart_key, item_key)
  #     redis.call("HSET", cart_key,
  #       "last_updated_at", now,
  #       "status", "active"
  #     )
  #     redis.call("HDEL", cart_key, "abandoned_at")
  #     redis.call("ZADD", activity_zset, now, cart_id)
  #     redis.call("EXPIRE", cart_key, ttl)
  #
  #     return 1
  #   LUA
  #
  #   mark_abandoned: <<~LUA
  #     local cart_key      = KEYS[1]
  #     local activity_zset = KEYS[2]
  #     local cart_id       = ARGV[1]
  #     local ttl           = tonumber(ARGV[2])
  #
  #     if redis.call("EXISTS", cart_key) == 0 then
  #       redis.call("ZREM", activity_zset, cart_id)
  #       return 0
  #     end
  #
  #     local status = redis.call("HGET", cart_key, "status")
  #     if status == "abandoned" then
  #       redis.call("ZREM", activity_zset, cart_id)
  #       return 1
  #     end
  #
  #     local now = redis.call("TIME")[1]
  #     redis.call("HSET", cart_key,
  #       "status", "abandoned",
  #       "abandoned_at", now
  #     )
  #     redis.call("EXPIRE", cart_key, ttl)
  #     redis.call("ZREM", activity_zset, cart_id)
  #     return 1
  #   LUA
  # }.freeze
end

