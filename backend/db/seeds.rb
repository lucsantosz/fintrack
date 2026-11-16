DEFAULT_CATEGORIES = {
  "expense" => [ "Alimentação", "Transporte", "Lazer", "Saúde", "Moradia", "Educação", "Outras despesas" ],
  "income" => [ "Salário", "Freelance", "Investimentos", "Outras receitas" ]
}.freeze

DEFAULT_CATEGORIES.each do |kind, names|
  names.each do |name|
    Category.find_or_create_by!(user_id: nil, kind: kind, name: name)
  end
end
