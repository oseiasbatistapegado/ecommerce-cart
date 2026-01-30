FactoryBot.define do
  factory :product do
    name { "Produto #{SecureRandom.hex(4)}" }
    price { 100.0 }
  end
end

