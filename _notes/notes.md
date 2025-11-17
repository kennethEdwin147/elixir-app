**Ok, récap de où on est rendu pour le MVP minimal:**

---

## **✅ CE QU'ON A FAIT:**

### **1. Controllers**
- ✅ `CreateController` - Flow de création (7 steps)
- ✅ `ViewController` - Afficher les wraps
- ✅ `UserController` - Dashboard avec `/user/wraps`

### **2. Templates HTML (basiques, sans CSS)**
- ✅ `create/new.html.eex` - Landing "Créer ton Wrapped"
- ✅ `create/step.html.eex` - Upload pour chaque slide
- ✅ `create/review.html.eex` - Preview avant génération
- ✅ `view/show.html.eex` - Afficher le wrap final
- ✅ `user/wraps.html.eex` - Liste des wraps de l'user

### **3. Routes**
- ✅ `/create` → CreateController
- ✅ `/v/:id` → ViewController  
- ✅ `/user/wraps` → UserController

---

## **❌ CE QU'IL RESTE À FAIRE:**

### **1. Gestion des uploads** (CRITIQUE)
```elixir
# Dans CreateController.post "/:id/step/:step_num"
# Faut gérer conn.params["photos"] et les sauvegarder
```

### **2. Sauvegarder les slides**
```elixir
# Créer dossier: priv/static/uploads/{wrap_id}/slide_{step_num}/
# Copier les photos uploadées
# Sauvegarder metadata (texte, etc.)
```

### **3. Générer le wrap final**
```elixir
# Dans CreateController.post "/:id/generate"
# Assembler toutes les slides
# Créer le HTML final dans priv/static/wraps/{wrap_id}/
```

### **4. Afficher le wrap généré**
```elixir
# Dans ViewController
# Charger les slides depuis priv/static/wraps/{wrap_id}/
# Render avec animations (HTML/CSS/JS)
```

### **5. Router config**
```elixir
# Ajouter forward dans router.ex
# Servir les fichiers statiques (uploads, wraps)
```

---

## **PROCHAINE ÉTAPE LOGIQUE:**

**Option A: Gestion des uploads** (backend)
- Coder la sauvegarde des photos uploadées
- Tester que ça marche

**Option B: Test du flow complet** (quick & dirty)
- Juste tester que les routes fonctionnent
- Upload fake, génération fake
- Valider le flow utilisateur

**Option C: Génération du wrap** (frontend)
- Créer le template HTML/CSS/JS pour afficher les slides
- Animations, transitions, etc.

---

**Tu veux qu'on fasse quoi en premier?**

1. **Coder les uploads** (backend solide)
2. **Tester le flow** (valider que tout est connecté)
3. **Design le wrap final** (la partie visuelle)

**Ton choix?** 🚀