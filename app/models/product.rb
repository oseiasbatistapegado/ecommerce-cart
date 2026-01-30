class Product < ApplicationRecord
  after_commit :invalidate_cache
  validates_presence_of :name, :price
  validates_numericality_of :price, greater_than_or_equal_to: 0

  def self.cached_find(id)
    Rails.cache.fetch("product:#{id}") { find(id) }
  end

  def self.cached_all
    Rails.cache.fetch("products:all") { all.to_a }
  end

  private

  def invalidate_cache
    Rails.cache.delete("product:#{id}")       # para cached_find
    Rails.cache.delete("products:all")        # para cached_all
  end
end
