class Phone < ApplicationRecord
  belongs_to :user, optional: true
end
