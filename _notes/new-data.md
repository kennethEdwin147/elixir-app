# ValoLFG - Instructions Base de Données

## Contexte
App multi-jeux de type "Social Club" pour gamers. Un user peut avoir UN profile par jeu (Valorant, Apex, etc.). 
Système de demandes de connexion asymétriques (pas de swipe mutuel), avec tracking des relations établies.

## Stack
- Elixir avec Ecto
- PostgreSQL
- UUID comme primary keys
- Timestamps en utc_datetime

## Tables à créer

### 1. games
- id (uuid, pk)
- slug (string, unique) - "valorant", "apex", "lol"
- name (string) - "Valorant", "Apex Legends"
- active (boolean, default true)
- created_at


### 2. users (Auth email/password)
- id (uuid, pk)
- email (string, unique, required)
- username (string, unique, required) - handle type "@mika"
- display_name (string, nullable) - nom affiché "Mika"
- password_hash (string, required)
- onboarding_completed (boolean, default false)
- is_premium (boolean, default false)
- created_at, updated_at

**Notes:**
- `password` sera un champ virtual dans le schema Ecto
- `username` doit être unique et servira de handle public
- `display_name` optionnel pour personnalisation
- `onboarding_completed` pour tracker si le profil est complété
```

## Changements dans les flows:

**Création de compte:**
```
1. User s'inscrit → email + password + username
2. INSERT users avec onboarding_completed = false
3. Redirect vers onboarding pour créer profile Valorant
4. Une fois profile créé → UPDATE onboarding_completed = true
```

### 3. profiles (Profil social par jeu)
- id (uuid, pk)
- user_id (fk users, cascade delete)
- game_id (fk games, restrict delete)
- bio (text, nullable)
- age_range (string, nullable) - "18-24", "25-30", "30+"
- rank (string, nullable) - "Gold 2", "Platinum", etc.
- region (string, nullable) - "EU West", "NA East"
- playstyle (string, nullable) - "tryhard", "chill", "mix"
- voice_required (boolean, default false)
- vibe_tags (array string, default []) - ["Mic ON", "Chill", "Ranked Only"]
- active (boolean, default true) - visible dans feed ou non
- last_boosted_at (datetime, nullable) - pour boost payant futur
- last_active_at (datetime, default now)
- created_at, updated_at

**Contrainte:** UNIQUE(user_id, game_id) - un profile max par jeu
**Index:** 
- (game_id, active, last_boosted_at DESC NULLS LAST, last_active_at DESC) - feed principal
- (game_id, rank, region) WHERE active = true - filtres
- GIN index sur vibe_tags - recherche par tags

### 4. game_specific_data (Key-value pour données spécifiques jeu)
- id (uuid, pk)
- profile_id (fk profiles, cascade delete)
- key (string, required) - "main_agent", "main_legend", "main_role"
- value (string, required) - "Jett", "Wraith", "ADC"

**Index:** (profile_id), (profile_id, key)

**Exemples:**
- Valorant: key="main_agent", value="Jett"
- Apex: key="main_legend", value="Wraith"
- LoL: key="main_role", value="ADC"

### 5. also_plays (Autres jeux joués - affinités)
- id (uuid, pk)
- user_id (fk users, cascade delete)
- game_id (fk games, cascade delete)

**Contrainte:** UNIQUE(user_id, game_id)

### 6. availabilities (Horaires récurrents)
- id (uuid, pk)
- profile_id (fk profiles, cascade delete)
- day_of_week (integer, required) - 0=Dimanche, 1=Lundi, ..., 6=Samedi
- start_time (time, required) - "19:00"
- end_time (time, required) - "23:00"

**Contrainte:** CHECK(day_of_week >= 0 AND day_of_week <= 6)
**Index:** (profile_id)

### 7. connection_requests (Demandes "Ça m'intéresse")
- id (uuid, pk)
- requester_id (fk users, cascade delete) - qui demande
- target_id (fk users, cascade delete) - à qui
- game_id (fk games, restrict delete)
- status (string, default "pending") - "pending", "accepted", "declined"
- message (text, nullable) - message optionnel avec demande
- created_at, updated_at

**Contraintes:**
- CHECK(requester_id != target_id) - pas se demander soi-même
- UNIQUE(requester_id, target_id, game_id) - une seule demande par game

**Index:**
- (target_id, status, game_id) - mes demandes reçues
- (requester_id, game_id) - mes demandes envoyées

### 8. connections (Relations établies)
- id (uuid, pk)
- user_id_1 (fk users, cascade delete)
- user_id_2 (fk users, cascade delete)
- game_id (fk games, restrict delete)
- play_count (integer, default 0) - combien de fois ils ont joué
- last_played_at (datetime, nullable)
- created_at, updated_at

**Contraintes:**
- CHECK(user_id_1 < user_id_2) - force ordre pour éviter doublons
- UNIQUE(user_id_1, user_id_2, game_id)

**Index:**
- (user_id_1, game_id)
- (user_id_2, game_id)

**Usage:** Pour chercher les connexions d'un user, faire WHERE user_id_1 = X OR user_id_2 = X

## Notes importantes

1. **Multi-jeux dès le start:** Un user peut avoir un profile Valorant + un profile Apex + un profile LoL
2. **Boost system:** Le tri du feed priorise `last_boosted_at` puis `last_active_at` (monétisation future)
3. **Vibe tags:** Array PostgreSQL pour matching rapide avec opérateur `&&`
4. **Connections order:** Toujours mettre le plus petit UUID en `user_id_1` pour éviter doublons
5. **Game-specific data:** Évite de hardcoder des colonnes par jeu dans profiles

## Flows principaux

**Création de profile:**
1. User se connecte (email/password) → INSERT users
2. User choisit un jeu (ex: Valorant) → INSERT profile avec game_id
3. User remplit bio, rank, main agent → UPDATE profile + INSERT game_specific_data

**Demande de connexion:**
1. User A voit profil de User B → clique "Ça m'intéresse"
2. INSERT connection_request avec status="pending"
3. User B reçoit notif, peut accept ou decline
4. Si accept: UPDATE status="accepted" + INSERT connection (avec user_id_1 < user_id_2)

**Feed principal:**
```sql
SELECT * FROM profiles 
WHERE game_id = ? AND active = true
ORDER BY 
  CASE WHEN last_boosted_at IS NOT NULL THEN 0 ELSE 1 END,
  last_boosted_at DESC NULLS LAST,
  last_active_at DESC
```

Crée la migration Ecto et les schemas avec ces specs.

## Ordre de développement suggéré

1. Migration + Schemas de base (games, users, profiles)
2. Seeds games (valorant actif, autres inactifs)
3. Auth email/password (créer/login user)
4. CRUD Profile pour Valorant (hardcodé pour MVP)
5. game_specific_data pour main_agent
6. Feed avec filtres basiques
7. connection_requests + acceptation
8. connections établies

Tables availabilities et also_plays peuvent attendre post-MVP.