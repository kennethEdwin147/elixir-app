# ValoLFG - Instructions Auth & Onboarding Multi-Jeux

## Contexte
Système d'authentification email/password avec onboarding multi-jeux. Un user peut créer plusieurs profils (un par jeu). L'onboarding est spécifique à chaque jeu.

---

## Pages & Routes

### Pages publiques (non-authentifié) ------- Deja Fait ------
- `/` - Homepage
- `/register` - Inscription
- `/login` - Connexion

### Pages authentifiées sans profil requis
- `/choose-game` - Sélection du jeu pour créer premier profil
- `/onboarding/:game` - Onboarding spécifique au jeu (valorant, apex, lol)
- `/logout` - Déconnexion ------ Deja Fait ------

### Pages authentifiées avec profil requis
- `/profiles` - Feed principal (redirect vers `/valorant` pour MVP)
- `/:game` - Feed du jeu spécifique (ex: `/valorant`)
- `/:game/profiles/:id` - Voir un profil
- `/:game/my-profile/edit` - Éditer mon profil pour ce jeu
- `/my-profile` - Vue globale de mes profils (tous jeux)
- `/connections` - Mes connexions (tous jeux)
- `/requests` - Mes demandes reçues (tous jeux)
- `/:game/connect/:id` - Demander connexion
- `/:game/requests/:id/accept` - Accepter demande
- `/:game/requests/:id/decline` - Décliner demande

---

## Flows utilisateur

### 1. Inscription (nouveau user)
```
/register 
→ Validation (email unique, username unique, password min 8 chars)
→ INSERT users (sans onboarding_completed, on ne l'utilise plus)
→ Hash password avec Bcrypt
→ Auto-login (créer session avec user_id)
→ REDIRECT /choose-game
```

### 2. Connexion (user existant)
```
/login
→ Authenticate (email OU username + password)
→ Créer session
→ Check: user a-t-il au moins 1 profil?
   - OUI → REDIRECT /profiles (ou /valorant pour MVP)
   - NON → REDIRECT /choose-game
```

### 3. Choix du jeu (pas de profil)
```
/choose-game
→ Afficher liste des jeux actifs (Valorant pour MVP)
→ Click sur jeu → POST /choose-game/:slug
→ REDIRECT /onboarding/:slug
```

### 4. Onboarding jeu spécifique
```
/onboarding/:game (ex: /onboarding/valorant)
→ Check: user a déjà profil pour ce jeu?
   - OUI → REDIRECT /:game
   - NON → Afficher formulaire 3 steps

Step 1 - Basics:
- Bio (text, optionnel)
- Age range (radio: 18-24, 25-30, 30+)

Step 2 - Jeu spécifique (Valorant):
- Rank (dropdown)
- Région (radio)
- Agent principal (dropdown)
- Agent secondaire (dropdown, optionnel)

Step 3 - Préférences:
- Playstyle (radio: tryhard, chill, mix)
- Voice required (checkbox)
- Vibe tags (checkboxes, 2-3 recommandé)

→ POST /onboarding/:game
→ Transaction:
   1. INSERT profile (user_id, game_id, bio, age_range, rank, region, playstyle, voice_required, vibe_tags)
   2. INSERT game_specific_data pour main_agent
   3. INSERT game_specific_data pour secondary_agent si présent
→ REDIRECT /:game (feed du jeu)
```

### 5. Ajouter un nouveau jeu (user avec profil existant)
```
User a profil Valorant, veut créer profil Apex:
→ Click "Apex" dans dropdown navbar
→ Pas de profil Apex → REDIRECT /onboarding/apex
→ Même flow onboarding que ci-dessus
→ REDIRECT /apex
```

---

## Protection des routes (Plugs)

### Plug 1: RequireAuth
```elixir
# Vérifie session user_id
# Si nil → redirect /login
# Sinon → assign :current_user
```
**Appliqué à:** Toutes les routes sauf `/`, `/register`, `/login`

### Plug 2: RequireProfile
```elixir
# Check: user a AU MOINS 1 profil (n'importe quel jeu)?
# Query: SELECT COUNT(*) FROM profiles WHERE user_id = ?
# Si 0 → redirect /choose-game
# Sinon → continue
```
**Appliqué à:** Routes `/profiles`, `/:game/*`, `/connections`, `/requests`

### Plug 3: RequireGameProfile (pour routes `/:game/*`)
```elixir
# Extraire game_slug du path (:game param)
# Get game par slug
# Check: user a profil pour CE jeu?
# Query: SELECT * FROM profiles WHERE user_id = ? AND game_id = ?
# Si nil → redirect /onboarding/:game
# Sinon → assign :current_game et :current_profile
```
**Appliqué à:** Routes `/:game/*` (feed, profil view, édition, connexions)

---

## Formulaires détaillés

### Registration `/register`
```
Créer un compte
───────────────

Email:          [____________]
Username:       [____________]  (@mika_fr)
Display Name:   [____________]  (optionnel)
Password:       [____________]
Confirm Pass:   [____________]

[Créer mon compte]

Déjà un compte? Se connecter
```

**Validations:**
- Email: format email, unique
- Username: 3-20 chars, alphanumeric + underscore, unique
- Password: min 8 chars
- Confirm password: match avec password

### Login `/login`
```
Connexion
─────────

Email ou Username:  [____________]
Password:           [____________]

☐ Se souvenir de moi

[Se connecter]

Pas de compte? S'inscrire
Mot de passe oublié?
```

**Backend:**
- Accepter email OU username dans le champ
- Authenticate avec Bcrypt.verify_pass

### Onboarding Step 1 `/onboarding/:game?step=1`
```
Bienvenue sur ValoLFG! 🎮
─────────────────────────

Commençons par les bases:

Bio courte (optionnel):
[_________________________________]
[_________________________________]
Ex: "Main Jett, cherche duo sérieux"

Tranche d'âge:
( ) 18-24
( ) 25-30
( ) 30+

[Suivant →]
```

### Onboarding Step 2 - Valorant
```
Ton profil Valorant
────────────────────

Rank actuel:
[Dropdown: Fer 1, Fer 2, Fer 3, Bronze 1, ..., Radiant]

Région:
( ) EU West
( ) EU East
( ) NA
( ) LATAM
( ) BR

Agent principal:
[Dropdown: Brimstone, Viper, Omen, ..., Vyse]

Agent secondaire (optionnel):
[Dropdown: -- Aucun --, Brimstone, ...]

[← Retour]  [Suivant →]
```

### Onboarding Step 3 - Préférences
```
Dernier step!
─────────────

Style de jeu:
( ) Tryhard - Je veux win
( ) Chill - Pour le fun
( ) Mix - Les deux

Micro requis?
☐ Oui

Vibe tags (sélectionne 2-3):
☐ Mic ON obligatoire
☐ Chill & Fun
☐ Tryhard
☐ Ranked seulement
☐ Unrated & Swift
☐ Flex tous rôles
☐ One-trick
☐ Shotcaller
☐ Support player
☐ Lurker

[← Retour]  [Terminer ✓]
```

---

## Feed principal `/:game` (ex: `/valorant`)

```
ValoLFG.gg | @mika_fr

[Valorant ▼] | Mon profil | Demandes (2) | Connexions | Déconnexion

[Filtres: Rank ▼ | Région ▼ | Playstyle ▼]

┌────────────────────────────────┐
│ @sarah_lurk • Platine 1        │
│ Main Cypher • EU West          │
│ "Lurker Cypher main. Je..."    │
│ [Lurker] [Mic ON]              │
│ 🟢 En ligne • [Ça m'intéresse] │
└────────────────────────────────┘

┌────────────────────────────────┐
│ @julie_controller • Diamant 2  │
│ Main Viper • EU West           │
│ "Main Viper/Omen. Je fume..."  │
│ [Mic ON] [Flex]                │
│ 🔴 Hors ligne • [Voir profil]  │
└────────────────────────────────┘
```

**Dropdown Valorant:**
```
Valorant ✓
Apex (créer profil)
LoL (créer profil)
```
- ✓ = profil existe pour ce jeu
- "créer profil" = redirect vers `/onboarding/:game`

---

## Navigation globale

### User sans aucun profil
```
Navbar: [Logo] | Déconnexion
→ Tout redirige vers /choose-game
```

### User avec au moins 1 profil
```
Navbar: [Jeu ▼] | Mon profil | Demandes (badge) | Connexions | Déconnexion
```

---

## Contextes requis

### ValoLFG.Accounts
- `register_user(attrs)` - Créer user avec password hash
- `authenticate(email_or_username, password)` - Login
- `get_user!(id)` - Récupérer user

### ValoLFG.Games
- `list_active()` - Jeux disponibles
- `get_by_slug!(slug)` - Get game par slug

### ValoLFG.Profiles
- `count_for_user(user_id)` - Nombre de profils du user
- `get_for_user_and_game(user_id, game_id)` - Profile spécifique
- `create_with_game_data(user, game_id, attrs)` - Transaction: profile + game_specific_data
- `list_for_game(game_id, filters)` - Feed avec filtres

### ValoLFG.Connections
- `create_request(attrs)` - Demande de connexion
- `accept_request(request_id)` - Accepter → créer connection
- `decline_request(request_id)` - Décliner
- `list_requests_for_user(user_id)` - Demandes reçues
- `list_connections_for_user(user_id)` - Connexions établies

---

## Notes importantes

1. **Pas de colonne `onboarding_completed`** - On check juste si `COUNT(profiles) > 0`
2. **Multi-steps onboarding** - Peut être 1 page avec JS ou 3 pages séparées (ton choix)
3. **Game slug dans URL** - `/:game/...` permet routing par jeu
4. **Session persistante** - "Se souvenir de moi" = cookie max_age long
5. **Validation côté serveur** - Toujours valider en backend, pas juste frontend
6. **Bcrypt pour passwords** - Hash avec `Bcrypt.hash_pwd_salt/1`, verify avec `Bcrypt.verify_pass/2`

---

## Pour le MVP (Valorant only)

Tu peux simplifier temporairement:
- `/profiles` → hardcode redirect vers `/valorant`
- Dropdown jeux → juste "Valorant" visible
- `/choose-game` → skip et redirect direct `/onboarding/valorant`

Mais l'archi reste multi-jeux ready pour quand tu actives Apex.