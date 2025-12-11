# Créer un user test
```elixir
MyApp.Services.UserService.create_user(%{
  "email" => "test@test.com",
  "username" => "test",
  "password" => "password123"
})

# Vérifier l'ID
user = MyApp.Services.UserService.find_by_email("test@test.com")
IO.inspect(user.id, label: "USER ID")
```

# A faire:
- Ajouter middleware pour vérifier que l'utilisateur est connecté
