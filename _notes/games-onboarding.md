# Task: Créer GameOnboardingController pour ValoLFG

## Contexte
L'auth (register/login) est déjà fait. Maintenant il faut créer le flow d'onboarding pour qu'un user authentifié puisse créer son profil Valorant.

## Routes à créer
```elixir
# Dans router.ex
scope "/", MyAppWeb do
  pipe_through [:browser, :require_auth]
  
  forward "/onboarding", to: MyApp.Controllers.GameOnboardingController
end
```

## GameOnboardingController

Créer `lib/my_app/controllers/game_onboarding_controller.ex`:

Le controller doit utiliser `Plug.Router` comme `AuthController`.
```elixir
defmodule MyApp.Controllers.GameOnboardingController do
  use Plug.Router
  
  plug :match
  plug :dispatch
  
  # GET /onboarding/:game
  get "/:game" do
    # Implémenter show logic
  end
  
  # POST /onboarding/:game
  post "/:game" do
    # Implémenter create logic
  end
end
```

### Route: GET /onboarding/:game
1. Récupérer le jeu par slug (conn.path_params["game"])
2. Vérifier que le jeu existe (MyApp.Games.get_by_slug!/1)
3. Récupérer current_user depuis conn.assigns
4. Vérifier si user a déjà un profil pour ce jeu
   - Si oui → redirect vers /:game (feed)
   - Si non → render template avec formulaire
5. Passer à la view: current_user, game

### Route: POST /onboarding/:game
1. Récupérer le jeu par slug (conn.path_params["game"])
2. Récupérer current_user depuis conn.assigns
3. Parser body params (utiliser Plug.Parsers si nécessaire)
4. Extraire les params du formulaire:
   - bio (string, optionnel)
   - age_range (string)
   - rank (string)
   - region (string)
   - playstyle (string: "tryhard", "chill", "mix")
   - voice_required (boolean)
   - vibe_tags (array de strings)
   - main_agent (string) - dans game_specific_data
   - secondary_agent (string, optionnel) - dans game_specific_data

5. Appeler `MyApp.Profiles.create_with_game_data(user, game.id, params)`
   - Si {:ok, profile} → redirect vers /:game avec flash success
   - Si {:error, changeset} → re-render "show.html" avec errors

## Template à créer

Créer `lib/my_app/templates/game_onboarding/show.html.eex`:

Formulaire HTML sémantique (pas de CSS !!) avec method="POST" action="/onboarding/<%= @game.slug %>":

**Step 1 - Basics:**
- Textarea: bio (optionnel, name="bio")
- Radio buttons: age_range ("18-24", "25-30", "30+", name="age_range")

**Step 2 - Valorant:**
- Select dropdown: rank (utiliser MyApp.Games.Valorant.ranks(), name="rank")
- Radio buttons: region ("EU West", "EU East", "NA", "LATAM", "BR", name="region")
- Select dropdown: main_agent (utiliser MyApp.Games.Valorant.agents(), name="main_agent")
- Select dropdown: secondary_agent (optionnel, avec "Aucun", name="secondary_agent")

**Step 3 - Préférences:**
- Radio buttons: playstyle ("tryhard", "chill", "mix", name="playstyle")
- Checkbox: voice_required (name="voice_required")
- Checkboxes multiples: vibe_tags (utiliser MyApp.Games.Valorant.vibe_tags(), name="vibe_tags[]")

Bouton submit: "Créer mon profil"

## Contexte Profiles nécessaire

Assure-toi que `MyApp.Profiles` a la fonction:
```elixir
def create_with_game_data(user, game_id, attrs) do
  Repo.transaction(fn ->
    # Extraire game_specific_data du attrs
    main_agent = attrs["main_agent"]
    secondary_agent = attrs["secondary_agent"]
    
    # Créer le profile
    profile = %Profile{}
    |> Profile.changeset(%{
      user_id: user.id,
      game_id: game_id,
      bio: attrs["bio"],
      age_range: attrs["age_range"],
      rank: attrs["rank"],
      region: attrs["region"],
      playstyle: attrs["playstyle"],
      voice_required: attrs["voice_required"] == "true" || attrs["voice_required"] == true,
      vibe_tags: attrs["vibe_tags"] || [],
      active: true,
      last_active_at: DateTime.utc_now()
    })
    |> Repo.insert!()
    
    # Créer game_specific_data pour main_agent
    if main_agent && main_agent != "" do
      %GameSpecificData{}
      |> GameSpecificData.changeset(%{
        profile_id: profile.id,
        key: "main_agent",
        value: main_agent
      })
      |> Repo.insert!()
    end
    
    # Créer game_specific_data pour secondary_agent si présent
    if secondary_agent && secondary_agent != "" && secondary_agent != "Aucun" do
      %GameSpecificData{}
      |> GameSpecificData.changeset(%{
        profile_id: profile.id,
        key: "secondary_agent",
        value: secondary_agent
      })
      |> Repo.insert!()
    end
    
    profile
  end)
end
```

## Module Valorant pour les données

Créer `lib/my_app/games/valorant.ex`:
```elixir
defmodule MyApp.Games.Valorant do
  @moduledoc """
  Données spécifiques à Valorant (ranks, agents, régions, vibe tags)
  """

  def ranks do
    ["Fer 1", "Fer 2", "Fer 3",
     "Bronze 1", "Bronze 2", "Bronze 3",
     "Argent 1", "Argent 2", "Argent 3",
     "Or 1", "Or 2", "Or 3",
     "Platine 1", "Platine 2", "Platine 3",
     "Diamant 1", "Diamant 2", "Diamant 3",
     "Ascendant 1", "Ascendant 2", "Ascendant 3",
     "Immortel 1", "Immortel 2", "Immortel 3",
     "Radiant"]
  end

  def agents do
    ["Brimstone", "Viper", "Omen", "Killjoy", "Cypher",
     "Sova", "Sage", "Phoenix", "Jett", "Reyna",
     "Raze", "Breach", "Skye", "Yoru", "Astra",
     "KAY/O", "Chamber", "Neon", "Fade", "Harbor",
     "Gekko", "Deadlock", "Iso", "Clove", "Vyse"]
  end

  def regions do
    ["EU West", "EU East", "NA", "LATAM", "BR"]
  end

  def vibe_tags do
    ["Mic ON obligatoire", "Chill & Fun", "Tryhard",
     "Ranked seulement", "Unrated & Swift", "Flex tous rôles",
     "One-trick", "Shotcaller", "Support player", "Lurker"]
  end
end
```

## Notes importantes
- Utiliser `Plug.Router` comme dans AuthController
- Utiliser HTML sémantique simple (pas de CSS inline compliqué)
- Validation côté serveur dans le changeset Profile
- Après création profile → redirect vers /:game (sera implémenté plus tard)
- Structure du projet: `lib/my_app/games/` pour tous les modules de jeux
- Gérer le parsing des checkboxes (vibe_tags[]) correctement