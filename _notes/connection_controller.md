# Task: Créer ConnectionController

## Contexte
Le contexte `MyApp.Contexts.Connection` existe déjà avec toutes les fonctions nécessaires.
Les users peuvent voir des profils dans le feed. Maintenant ils doivent pouvoir:
1. Envoyer des demandes "Ça m'intéresse"
2. Voir les demandes reçues
3. Accepter/décliner des demandes
4. Voir leurs connexions établies

## Route à créer
```elixir
# Dans router.ex
scope "/", MyAppWeb do
  pipe_through [:browser, :require_auth, :require_profile]
  
  forward "/connections", to: MyApp.Controllers.ConnectionController
end
```

---

## ConnectionController à créer

Fichier: `lib/my_app/controllers/connection_controller.ex`

Le controller utilise `Plug.Router` et appelle les fonctions du contexte `MyApp.Contexts.Connection`.

---

## Routes du controller

### 1. POST /connections/request
**But:** Envoyer une demande "Ça m'intéresse" à un autre joueur

**Params attendus:**
- `target_id` (string/UUID) - ID de l'utilisateur cible
- `game_id` (string/UUID) - ID du jeu
- `message` (string, optionnel) - Message personnalisé

**Logic:**
1. Récupérer `current_user` depuis `conn.assigns.current_user`
2. Extraire les params: `target_id`, `game_id`, `message`
3. Appeler `MyApp.Contexts.Connection.send_request/1` avec:
```elixir
   %{
     requester_id: current_user.id,
     target_id: params["target_id"],
     game_id: params["game_id"],
     message: params["message"]
   }
```
4. Gérer les réponses:
   - `{:ok, request}` → Flash success "Demande envoyée!" + redirect vers `/discover/:game`
   - `{:error, :self_request}` → Flash error "Tu ne peux pas t'envoyer une demande" + redirect back
   - `{:error, :already_connected}` → Flash info "Vous êtes déjà connectés" + redirect back
   - `{:error, :request_exists}` → Flash info "Demande déjà envoyée" + redirect back

**Appelé depuis:** Formulaire dans le feed de profils (bouton "Ça m'intéresse")

---

### 2. GET /connections/requests
**But:** Afficher toutes les demandes reçues en attente

**Logic:**
1. Récupérer `current_user`
2. Récupérer le `game_id` depuis les query params OU depuis le profile actuel de l'user
3. Appeler `MyApp.Contexts.Connection.list_received_requests(current_user.id, game_id, status: "pending")`
4. Render template `requests.html.eex` avec:
   - `requests` - liste des demandes avec requester preloadé
   - `game` - le jeu concerné

**Template:** Afficher pour chaque demande:
- Photo/avatar du demandeur (si dispo)
- Username: `@username`
- Rank et région
- Message optionnel s'il y en a un
- Jeu concerné
- Formulaire avec 2 boutons:
```html
  <form method="POST" action="/connections/requests/<%= request.id %>/accept">
    <button>Accepter</button>
  </form>
  <form method="POST" action="/connections/requests/<%= request.id %>/decline">
    <button>Décliner</button>
  </form>
```

---

### 3. POST /connections/requests/:id/accept
**But:** Accepter une demande de connexion

**Logic:**
1. Récupérer `request_id` depuis `conn.path_params["id"]`
2. Récupérer la demande avec `MyApp.Contexts.Connection.get_request(request_id)`
3. **Sécurité:** Vérifier que `request.target_id == current_user.id` (seul le destinataire peut accepter)
   - Si non → Flash error "Non autorisé" + redirect "/"
4. Appeler `MyApp.Contexts.Connection.accept_request(request_id)`
5. Gérer les réponses:
   - `{:ok, connection}` → Flash success "Connexion acceptée! Vous pouvez maintenant jouer ensemble" + redirect "/connections"
   - `{:error, :not_found}` → Flash error "Demande introuvable" + redirect "/connections/requests"
   - `{:error, :already_accepted}` → Flash info "Demande déjà acceptée" + redirect "/connections"

**Note:** La fonction `accept_request/1` crée automatiquement la connexion ET met à jour le status de la demande.

---

### 4. POST /connections/requests/:id/decline
**But:** Décliner une demande de connexion

**Logic:**
1. Récupérer `request_id` depuis `conn.path_params["id"]`
2. Récupérer la demande avec `MyApp.Contexts.Connection.get_request(request_id)`
3. **Sécurité:** Vérifier que `request.target_id == current_user.id`
   - Si non → Flash error "Non autorisé" + redirect "/"
4. Appeler `MyApp.Contexts.Connection.decline_request(request_id)`
5. Gérer les réponses:
   - `{:ok, _}` → Flash info "Demande déclinée" + redirect "/connections/requests"
   - `{:error, :not_found}` → Flash error "Demande introuvable" + redirect "/connections/requests"

---

### 5. GET /connections
**But:** Afficher toutes les connexions établies

**Logic:**
1. Récupérer `current_user`
2. Récupérer le `game_id` depuis query params OU profile actuel
3. Appeler `MyApp.Contexts.Connection.list_connections(current_user.id, game_id)`
4. Pour chaque connexion, déterminer qui est l'autre user:
```elixir
   other_user_id = if connection.user_id_1 == current_user.id do
     connection.user_id_2
   else
     connection.user_id_1
   end
```
5. Preload les users pour afficher leurs infos
6. Render template `index.html.eex` avec:
   - `connections` - liste des connexions
   - `game` - le jeu

**Template:** Afficher pour chaque connexion:
- Username de l'autre personne
- Son Discord username (visible car connexion établie!)
- Rank et région
- Date de connexion: `Connectés depuis le <%= format_date(connection.inserted_at) %>`
- Nombre de parties jouées: `<%= connection.play_count %> parties ensemble`
- Bouton optionnel "On a joué ensemble" (pour plus tard, incrémente play_count)

---

## Intégration dans le feed

**Modifier le template du feed** (`lib/my_app/templates/profile_discovery/valorant.html.eex`):

Remplacer le bouton "Ça m'intéresse" par un formulaire:
```html
<form method="POST" action="/connections/request">
  <input type="hidden" name="target_id" value="<%= @current_match.profile.user_id %>">
  <input type="hidden" name="game_id" value="<%= @game.id %>">
  <button type="submit">Ça m'intéresse →</button>
</form>
```

Le bouton "Passer" peut rester un simple bouton qui navigue vers le profil suivant (pas besoin de POST).

---

## Templates à créer

### 1. `lib/my_app/templates/connections/requests.html.eex`
Liste des demandes reçues en attente
```html
<h1>Demandes de connexion reçues</h1>

<%= if Enum.empty?(@requests) do %>
  <p>Aucune demande en attente</p>
<% else %>
  <%= for request <- @requests do %>
    <div>
      <h2>@<%= request.requester.username %></h2>
      <p>Pour <%= request.game.name %></p>
      
      <%= if request.message do %>
        <p>Message: "<%= request.message %>"</p>
      <% end %>
      
      <form method="POST" action="/connections/requests/<%= request.id %>/accept">
        <button>Accepter</button>
      </form>
      
      <form method="POST" action="/connections/requests/<%= request.id %>/decline">
        <button>Décliner</button>
      </form>
    </div>
  <% end %>
<% end %>
```

### 2. `lib/my_app/templates/connections/index.html.eex`
Liste des connexions établies
```html
<h1>Mes connexions</h1>

<%= if Enum.empty?(@connections) do %>
  <p>Aucune connexion pour l'instant</p>
<% else %>
  <%= for {connection, other_user} <- @connections do %>
    <div>
      <h2>@<%= other_user.username %></h2>
      <p>Discord: <%= other_user.discord_username %></p>
      <p>Jeu: <%= connection.game.name %></p>
      <p><%= connection.play_count %> parties jouées ensemble</p>
    </div>
  <% end %>
<% end %>
```

**Note importante:** Dans le controller pour `GET /connections`, préparer les données avec l'autre user:
```elixir
# Après avoir récupéré les connexions
connections_with_users = Enum.map(connections, fn connection ->
  other_user_id = if connection.user_id_1 == current_user.id do
    connection.user_id_2
  else
    connection.user_id_1
  end
  
  other_user = MyApp.Repo.get!(MyApp.Schemas.User, other_user_id)
  {connection, other_user}
end)

# Passer à la view
render(conn, "index.html.eex", connections: connections_with_users, current_user: current_user)
```

Créer `lib/my_app/views/connections_view.ex`:
```elixir
defmodule MyApp.Views.ConnectionsView do
  def get_other_user(connection, current_user) do
    if connection.user_id_1 == current_user.id do
      # Récupérer user_id_2
      MyApp.Repo.get!(MyApp.Schemas.User, connection.user_id_2)
    else
      # Récupérer user_id_1
      MyApp.Repo.get!(MyApp.Schemas.User, connection.user_id_1)
    end
  end

  def format_date(datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y")
  end
end
```

---

## Notes importantes

### Sécurité
- **Toujours vérifier** que `current_user` est autorisé (ex: seul le target peut accepter/décliner)
- Ne jamais faire confiance aux params sans validation

### Flash messages
- Utiliser `put_flash(conn, :success, "message")` pour les actions réussies
- Utiliser `put_flash(conn, :error, "message")` pour les erreurs
- Utiliser `put_flash(conn, :info, "message")` pour les infos neutres

### Redirects
- Après POST → toujours redirect (pattern Post/Redirect/Get)
- Utiliser `redirect(conn, to: "/path")` de Plug.Conn

### Preloading
- Le contexte `Connection` preload déjà les associations nécessaires
- Pas besoin de faire des queries supplémentaires dans le controller

### Game ID
Pour simplifier le MVP, tu peux hardcoder Valorant:
```elixir
game = MyApp.Contexts.Games.get_by_slug!("valorant")
```

Plus tard, tu récupéreras le game_id depuis le profil actuel de l'user.

---

## Exemple complet d'une route
```elixir
defmodule MyApp.Controllers.ConnectionController do
  use Plug.Router
  
  plug :match
  plug :dispatch
  
  # POST /connections/request
  post "/request" do
    current_user = conn.assigns.current_user
    params = conn.params
    
    case MyApp.Contexts.Connection.send_request(%{
      requester_id: current_user.id,
      target_id: params["target_id"],
      game_id: params["game_id"],
      message: params["message"]
    }) do
      {:ok, _request} ->
        conn
        |> put_flash(:success, "Demande envoyée!")
        |> redirect(to: "/discover/valorant")
      
      {:error, :self_request} ->
        conn
        |> put_flash(:error, "Tu ne peux pas t'envoyer une demande")
        |> redirect(to: "/discover/valorant")
      
      {:error, :already_connected} ->
        conn
        |> put_flash(:info, "Vous êtes déjà connectés")
        |> redirect(to: "/connections")
      
      {:error, :request_exists} ->
        conn
        |> put_flash(:info, "Demande déjà envoyée")
        |> redirect(to: "/discover/valorant")
    end
  end
  
  # Autres routes...
end
```

Voilà! Tout est expliqué en détail. Le controller fait juste le mapping entre HTTP et le contexte `Connection`.