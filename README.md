Criando formulários complexos com Rails
=======================================

Formulários em relação 1:n (Dropdown select HTML, buscando do BD)
-----------------------------------------------------------------
Referência.: http://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/collection_select

A caixa de seleção funciona em uma relação 1:n.
Exemplo.: Modelo user com belongs_to kind; modelo kind com has_many users (User pertence a um Kind e Kind possui muitos Users).
Nesse caso, o user armazena o id do kind, logo queremos que no formulário do user, exista uma lista com todos os kinds para seleção.

Para fazer esta firula, iremos usar o collection_select que funciona da seguinte forma:

Estrutura do collection_select(Assinatura do método):
```ruby
collection_select(object, method, collection, value_method, text_method, options = {}, html_options = {})
```
Onde:
* object: Qual o objeto do formulário, no caso User
* method: Campo que receberá o valor: kind_id
* collection: Coleção de onde virá os dados: Kinds.all
* value_method: O que precisa armazenar: no caso o id
* text_method: O que será exibido
* html_options: Opcional: css

Ficando assim:
```ruby
# app/views/users/_form.html.erb
<%= f.collection_select(:kind_id, @kind_options_for_select, :id, :description) %>
```
Onde @kind_options_for_select é uma variável que deve ser setada nos métodos new e edit do users_controller.rb, para retornar a collection(coleção de onde virá os dados):
```ruby
# app/controllers/users_controller.rb
@kind_options_for_select = Kind.all
```

Formulários complexos com has_one usando field_for
--------------------------------------------------
Referência.: http://apidock.com/rails/ActionView/Helpers/FormHelper/fields_for

Tendo o model: User has_one address e address belongs_to user (user tem um endereço e endereço pertence a um user); podemos ver que queremos cadastrar um address dentro do formulário do user de forma aninhada. São os formulários aninhados.

Primeiramente, devemos fazer com que o model de user aceite os atributos de address (Sem essa função, a variável f do formulário não entende os atributos do address como fazendo parte do user):
```ruby
# app/model/user.rb
accepts_nested_attributes_for :address
```

Colocar no belongs_to do address: É necessário optional true no rails 5:
```ruby
# app/models/address.rb
belongs_to :user, optional: true
```
Em seguida devemos colocar o form de address dentro do form de user:
```ruby
app/views/user/_form.html.erb
<%= f.fields_for @address do |ff| %>
  <div class="field">
    <%= ff.label :street %>
    <%= ff.text_field :street %>
  </div>
  <div class="field">
    <%= ff.label :city %>
    <%= ff.text_field :city %>
  </div>
  <div class="field">
    <%= ff.label :state %>
    <%= ff.text_field :state %>
  </div>
<% end %>
```

Onde @address dever ser instanciado no new e no edit do controller de user
```ruby
@user.build_address
```
Mas ainda não funciona ao submeter o formulário, ainda resta aceitar os parâmetros de address no método user_params do users_controller:
```ruby
params.require(:user).permit(:name, :age, :email, :kind_id, address_attributes: [:street, :city, :state])
```

Criar uma caixa de seleção de estados - select e options_for_select
-------------------------------------------------------------------
Referências.:
http://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html
http://apidock.com/rails/v3.2.1/ActionView/Helpers/FormOptionsHelper/options_for_select

Agora vamos criar uma caixa de seleção de estados, semelhante à caixa do kind, porém, a diferença será que os dados de estado não serão provenientes do banco de dados e sim de um array com todos os estados e suas respectivas siglas, então não usaremos collection_select e sim options_for_select, através do select.

Colocaremos o array em um helper que conterá todos os estados para despoluir a view. Como queremos que o helper fique disponível para toda a aplicação, usaremos a application_helper.rb

Copiamos o array de estados para application_helper
```ruby
ESTADOS_BRASILEIROS = [
  ["Acre", "AC"],
  ["Alagoas", "AL"],
  ["Amapá", "AP"],
  ["Amazonas", "AM"],
  ["Bahia", "BA"],
  ["Ceará", "CE"],
  ["Distrito Federal", "DF"],
  ["Espírito Santo", "ES"],
  ["Goiás", "GO"],
  ["Maranhão", "MA"],
  ["Mato Grosso", "MT"],
  ["Mato Grosso do Sul", "MS"],
  ["Minas Gerais", "MG"],
  ["Pará", "PA"],
  ["Paraíba", "PB"],
  ["Paraná", "PR"],
  ["Pernambuco", "PE"],
  ["Piauí", "PI"],
  ["Rio de Janeiro", "RJ"],
  ["Rio Grande do Norte", "RN"],
  ["Rio Grande do Sul", "RS"],
  ["Rondônia", "RO"],
  ["Roraima", "RR"],
  ["Santa Catarina", "SC"],
  ["São Paulo", "SP"],
  ["Sergipe", "SE"],
  ["Tocantins", "TO"]
]
```
E em seguida criamos um helper que devolve options_for_select:
```ruby
def options_for_states(selected)
  options_for_select(ESTADOS_BRASILEIROS, selected)
end
```

Agora colocamos o método no formulário de user view:
```ruby
<%= ff.select :state, options_for_states(@user.address.state) %>
```

Criando campos dinamicamente em um relacionamento has_many com a gem Cocoon
---------------------------------------------------------------------------

Neste relacionamento, user has_many phones e phones belongs_to user (user tem muitos phones e cada phone pertence a um user)

Devemos liberar os strong_parameters de phone no controller de users:
```ruby
# app/controllers/users_controller.rb
def user_params
  params.require(:user).permit(:name, :age, :email, :kind_id,
  address_attributes: [:street, :city, :state],
  phones_attributes: [:id, :phone, :_destroy])
end
```

Agora adicionaremos no gemfile a gem cocoon:
```ruby
gem 'cocoon'
```

Ativar a cocoon no javascript
```ruby
//= require cocoon
```

Adicionar o accepts_nested_attributes_for no user:
```ruby
accepts_nested_attributes_for :phones, reject_if: :all_blank, allow_destroy: true
```

onde o reject_if irá rejeitar caso o campo fique em branco, e o allow_destroy é para poder-mos apagar os campos de telefone no form.

Agora iremos adicionar os helpers do cocoon:
link_to_add_association: Adiciona um botão para adicionar um novo Campo
Para funcionar todos itens do form devem estar dentro de uma div com id="phones"(nome do model referenciado no plural) e todos os inputs devem estar dentro de uma div de class="nested_fields", bem como os campos devem estar em uma partial de nome(<association_object_singular>_fields)

```ruby
<div id="phones">
  <%= link_to_add_association('[Adicionar telefone]', f, :phones) %>
  <%= f.fields_for :phones do |fff| %>
    <%= render partial: "phone_fields", locals: { f:fff } %>
  <% end %>
</div>
```ruby

Criar um partial com o nome: _phone_fields.html.erb
```ruby
<div class="nested-fields">
  <div class="field">
    <%= f.label :phone %>
    <%= f.text_field :phone %>
    <%= link_to_remove_association('remover', f) %>
  </div>
</div>
```
