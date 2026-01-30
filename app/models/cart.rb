class Cart
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :status, :string, default: "active"
  attribute :abandoned_at, :datetime

  def mark_abandoned!
    return if abandoned?

    self.status = "abandoned"
    self.abandoned_at = Time.current
  end

  def active?
    status == "active"
  end

  def abandoned?
    status == "abandoned"
  end
end

