class User < ApplicationRecord
  has_one :address
  has_many :phones
  belongs_to :kind

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :phones, reject_if: :all_blank, allow_destroy: true
end
