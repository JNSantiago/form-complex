json.extract! address, :id, :street, :city, :state, :created_at, :updated_at
json.url address_url(address, format: :json)
