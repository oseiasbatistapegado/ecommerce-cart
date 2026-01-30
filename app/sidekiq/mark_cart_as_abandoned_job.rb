class MarkCartAsAbandonedJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: false

  BATCH_SIZE = 500

  def perform
    redis  = REDIS
    cutoff = Time.now.to_i - 3.hours.to_i

    loop do
      session_ids = redis.zrangebyscore(
        CartService::LAST_ACTIVITY_ZSET,
        0,
        cutoff,
        limit: [0, BATCH_SIZE]
      )

      break if session_ids.empty?

      session_ids.each do |session_id|
        CartService.new(session_id).mark_abandoned!
      end
    end
  end
end

