OK! Voici l'instruction mise à jour avec templates par jeu:

```markdown
# Task: Créer ProfileDiscoveryController pour le feed de matching

## Contexte
Auth et onboarding sont faits. Maintenant on crée le feed principal où les users découvrent des profils compatibles.

## Routes à créer

```elixir
# Dans router.ex
scope "/", MyAppWeb do
  pipe_through [:browser, :require_auth, :require_profile]
  
  forward "/discover/:game", to: MyApp.Controllers.ProfileDiscoveryController
end
```

## ProfileDiscoveryController

Créer `lib/my_app/controllers/profile_discovery_controller.ex`:

Le controller doit utiliser `Plug.Router`.

```elixir
defmodule MyApp.Controllers.ProfileDiscoveryController do
  use Plug.Router
  
  plug :match
  plug :dispatch
  
  # GET /discover/:game (ex: /discover/valorant)
  get "/" do
    # Implémenter feed logic
  end
  
  # GET /discover/:game/profiles/:id
  get "/profiles/:id" do
    # Implémenter profile detail logic
  end
end
```

---

## Route 1: GET /discover/:game (Feed principal)

**Logic:**
1. Récupérer le jeu par slug (conn.path_params["game"])
2. Vérifier que le jeu existe (MyApp.Games.get_by_slug!/1)
3. Récupérer current_user depuis conn.assigns
4. Vérifier que user a un profil pour ce jeu:
   - Si non → redirect vers /onboarding/:game
5. Appeler `MyApp.Matching.daily_matches(user, game.id)` pour obtenir les matchs du jour
6. Render le template selon le jeu:
   - Si game.slug == "valorant" → render "_valorant.html.eex"
   - Si game.slug == "apex" → render "_apex.html.eex"
   - Si game.slug == "lol" → render "_lol.html.eex"
   - Sinon → render "_generic.html.eex"

Passer à la view:
- matches: liste des profils avec raisons
- current_match: premier profil de la liste
- current_index: 0
- total: nombre total de matchs
- game: le jeu actuel
- current_user: l'utilisateur connecté

---

## Templates à créer

**Structure:**
```
lib/my_app/templates/profile_discovery/
├─ index.html.eex (dispatcher)
├─ _valorant.html.eex
├─ _apex.html.eex (pour futur)
├─ _lol.html.eex (pour futur)
└─ show.html.eex (profil détaillé)
```

### Template principal: `index.html.eex`

```eex
<%= case @game.slug do %>
  <% "valorant" -> %>
    <%= render "_valorant.html.eex", assigns %>
  <% "apex" -> %>
    <%= render "_apex.html.eex", assigns %>
  <% "lol" -> %>
    <%= render "_lol.html.eex", assigns %>
  <% _ -> %>
    <p>Jeu non supporté</p>
<% end %>
```

### Template Valorant: `_valorant.html.eex`

HTML sémantique simple pour afficher 1 profil à la fois:

```html
<div>
  <p><%= @total %> nouveaux joueurs compatibles aujourd'hui</p>
</div>

<div>
  <button>←</button>
  <span><%= @current_index + 1 %>/<%= @total %></span>
  <button>→</button>
</div>

<div>
  <h1>@<%= @current_match.profile.user.username %></h1>
  <p><%= @current_match.profile.rank %> • <%= @current_match.profile.region %></p>
  
  <div>
    <!-- Récupérer main_agent depuis game_specific_data -->
    <p>Main <%= get_agent(@current_match.profile) %> • Sentinelle</p>
    
    <!-- Disponibilités -->
    <p>Disponible: <%= format_availabilities(@current_match.profile.availabilities) %></p>
    
    <!-- Bio -->
    <p>"<%= @current_match.profile.bio %>"</p>
    
    <!-- Vibe tags -->
    <p>Style de jeu:</p>
    <%= for tag <- @current_match.profile.vibe_tags do %>
      <span><%= tag %></span>
    <% end %>
  </div>
  
  <!-- Status -->
  <p>En ligne maintenant</p>
  
  <!-- Actions -->
  <button>Ça m'intéresse →</button>
  <button>Passer</button>
</div>

<!-- Raisons du match -->
<div>
  <p>Pourquoi <%= @current_match.profile.user.username %>?</p>
  <%= for reason <- @current_match.reasons do %>
    <p>→ <%= reason %></p>
  <% end %>
</div>
```

### Template Apex: `_apex.html.eex` (placeholder pour futur)

```html
<div>
  <p><%= @total %> nouveaux joueurs compatibles aujourd'hui</p>
</div>

<div>
  <h1>@<%= @current_match.profile.user.username %></h1>
  <p><%= @current_match.profile.rank %> • <%= @current_match.profile.region %></p>
  
  <div>
    <p>Main <%= get_legend(@current_match.profile) %></p>
    <p>"<%= @current_match.profile.bio %>"</p>
    
    <%= for tag <- @current_match.profile.vibe_tags do %>
      <span><%= tag %></span>
    <% end %>
  </div>
  
  <button>Ça m'intéresse →</button>
  <button>Passer</button>
</div>

<div>
  <p>Pourquoi <%= @current_match.profile.user.username %>?</p>
  <%= for reason <- @current_match.reasons do %>
    <p>→ <%= reason %></p>
  <% end %>
</div>
```

### Template LoL: `_lol.html.eex` (placeholder pour futur)

Similaire à Apex mais avec "Main champion" au lieu de "Main legend".

---

## View helpers nécessaires

Créer `lib/my_app/views/profile_discovery_view.ex`:

```elixir
defmodule MyApp.Views.ProfileDiscoveryView do
  # Helper pour récupérer l'agent principal (Valorant)
  def get_agent(profile) do
    case Enum.find(profile.game_specific_data, fn data -> data.key == "main_agent" end) do
      nil -> "Inconnu"
      data -> data.value
    end
  end
  
  # Helper pour récupérer la legend principale (Apex)
  def get_legend(profile) do
    case Enum.find(profile.game_specific_data, fn data -> data.key == "main_legend" end) do
      nil -> "Inconnu"
      data -> data.value
    end
  end
  
  # Helper pour formater les disponibilités
  def format_availabilities(availabilities) do
    availabilities
    |> Enum.map(fn avail -> 
      day_name(avail.day_of_week) <> " " <> 
      Time.to_string(avail.start_time) <> "-" <> 
      Time.to_string(avail.end_time)
    end)
    |> Enum.join(", ")
  end
  
  defp day_name(0), do: "Dim"
  defp day_name(1), do: "Lun"
  defp day_name(2), do: "Mar"
  defp day_name(3), do: "Mer"
  defp day_name(4), do: "Jeu"
  defp day_name(5), do: "Ven"
  defp day_name(6), do: "Sam"
end
```

---

## Route 2: GET /discover/:game/profiles/:id (Profil détaillé)

**Logic:**
1. Récupérer profile_id depuis conn.path_params["id"]
2. Récupérer le profil (MyApp.Profiles.get!/1 avec preload :user, :game, :game_specific_data, :availabilities)
3. Vérifier que le profil appartient au jeu (profile.game.slug == game_slug)
4. Render template show.html.eex avec:
   - profile: le profil complet
   - game: le jeu

**Template:** `show.html.eex`

Même layout que le feed mais version statique (pas de navigation ← →):
- Afficher toutes les infos du profil
- Bouton "Retour au feed" → /discover/:game

---

## Contexte Matching (Version MVP simplifiée)

Créer `lib/my_app/matching.ex`:

```elixir
defmodule MyApp.Matching do
  alias MyApp.{Repo, Profiles}
  import Ecto.Query

  @doc """
  Version MVP: Retourne les 5 premiers profils actifs du jeu (sauf current_user)
  
  TODO: Implémenter l'algorithme complet avec:
  - Scoring basé sur rank, région, horaires, playstyle
  - Calcul des raisons de matching
  - Tri par score
  - Cache quotidien
  """
  def daily_matches(user, game_id, limit \\ 5) do
    # Récupérer profils actifs du jeu (sauf current_user)
    profiles = 
      from(p in Profiles.Profile,
        where: p.game_id == ^game_id and 
               p.user_id != ^user.id and
               p.active == true,
        preload: [:user, :game_specific_data, :availabilities],
        limit: ^limit
      )
      |> Repo.all()
    
    # Pour MVP: retourner avec des raisons génériques
    Enum.map(profiles, fn profile ->
      %{
        profile: profile,
        score: 5, # Score fictif pour MVP
        reasons: generate_mock_reasons(profile) # Raisons génériques
      }
    end)
  end

  # Générer des raisons génériques pour MVP
  defp generate_mock_reasons(profile) do
    [
      "Même région (#{profile.region})",
      "Rank compatible",
      "Profil actif"
    ]
  end

  # TODO: Implémenter calculate_match_score/2 avec l'algo complet
  # defp calculate_match_score(profile_a, profile_b) do
  #   # Scoring basé sur:
  #   # - Rank proximity (poids 3)
  #   # - Région (poids 3)
  #   # - Horaires overlap (poids 2)
  #   # - Playstyle compatibility (poids 2)
  #   # - Voice requirement (poids 1)
  #   # - Vibe tags overlap (poids 1 par tag)
  # end
end
```

---

## Contexte Profiles - Fonction helper nécessaire

Ajouter dans `lib/my_app/profiles.ex`:

```elixir
def get_for_user_and_game(user_id, game_id) do
  Repo.get_by(Profile, user_id: user_id, game_id: game_id)
end
```

---

## Notes importantes

- **Templates séparés par jeu** pour faciliter la personnalisation future
- **HTML sémantique simple** (pas de CSS complexe pour MVP)
- **Version MVP:** Matching simplifié, on améliore l'algo après
- **Navigation profils:** Pour MVP, peut être juste des liens `?index=0`, `?index=1`, etc.
- **Boutons actions:** "Ça m'intéresse" et "Passer" ne font rien pour l'instant (on implémente ConnectionController après)
- **TODO clairement marqués** dans le code pour l'algo complet
- **View helpers** pour extraire les données game-specific proprement

---

## Prochaine étape après ce controller

Une fois le feed visible, on implémentera:
1. ConnectionController (gérer "Ça m'intéresse" / "Passer")
2. Algorithme de matching complet avec scoring
3. Cache des matchs quotidiens
```

Ah OK parfait! Donc:

## 1. Pas de dispatcher, juste template Valorant direct

```markdown
## Templates à créer

**Pour MVP: Un seul template Valorant**

Créer `lib/my_app/templates/profile_discovery/valorant.html.eex`:

HTML sémantique simple pour afficher 1 profil à la fois:


```html
<div>
  <p><%= @total %> nouveaux joueurs compatibles aujourd'hui</p>
</div>

<div>
  <button>←</button>
  <span><%= @current_index + 1 %>/<%= @total %></span>
  <button>→</button>
</div>

<div>
  <h1>@<%= @current_match.profile.user.username %></h1>
  <p><%= @current_match.profile.rank %> • <%= @current_match.profile.region %></p>
  
  <div>
    <!-- Récupérer main_agent depuis game_specific_data -->
    <p>Main <%= get_agent(@current_match.profile) %> • Sentinelle</p>
    
    <!-- Disponibilités -->
    <p>Disponible: <%= format_availabilities(@current_match.profile.availabilities) %></p>
    
    <!-- Bio -->
    <p>"<%= @current_match.profile.bio %>"</p>
    
    <!-- Vibe tags -->
    <p>Style de jeu:</p>
    <%= for tag <- @current_match.profile.vibe_tags do %>
      <span><%= tag %></span>
    <% end %>
  </div>
  
  <!-- Status -->
  <p>En ligne maintenant</p>
  
  <!-- Actions -->
  <button>Ça m'intéresse →</button>
  <button>Passer</button>
</div>

<!-- Raisons du match -->
<div>
  <p>Pourquoi <%= @current_match.profile.user.username %>?</p>
  <%= for reason <- @current_match.reasons do %>
    <p>→ <%= reason %></p>
  <% end %>
</div>
```

**Dans le controller:** Render directement "valorant.html.eex" (pas de dispatcher)

**Templates Apex/LoL:** Créer des fichiers vides `apex.html.eex` et `lol.html.eex` avec juste:
```html
<p>Coming soon</p>
```
```

---

## 2. Où mettre `matching.ex`

```
lib/my_app/
├─ services/
│  └─ matching.ex

etc.
```
**Ma recommandation:** Racine `lib/my_app/matching.ex` pour garder simple au début.

Ça te va?

