**ÇA AVANCE BIEN ! 🎉**

**Je vois sur votre screenshot :**

✅ Feed d'annonces (marche !)  
✅ Affichage par jeu (`/fortnite`, `/league`, `/apex`)  
✅ Timestamp ("28min ago", "2h ago")  
✅ Username (@test)  
✅ Description  
✅ Boutons "Comm Like interesse"  

---

## **CE QUI RESTE POUR LE MVP :**

### **🔴 PRIORITÉ 1 (essentiel) :**

**1. Pages rooms par jeu**
```
/valorant → Page dédiée Valorant
/league → Page dédiée League
/apex → Page dédiée Apex

Actuellement: Feed montre tout mélangé
Besoin: Pages séparées par jeu
```

**2. Rendre les boutons fonctionnels**
```
✅ "Comm" → Aller aux commentaires
✅ "Like" → Upvote (increment count)
✅ "interesse" → Marquer intéressé

Actuellement: Boutons affichés mais pas fonctionnels
```

**3. Afficher Discord ID dans les cards**
```
Actuellement: Pas de Discord visible
Besoin: Afficher Discord pour contact

Ex: "Discord: username#1234"
```

**4. Sidebar avec liste jeux + counts**
```
Actuellement: Sidebar basique
Besoin: 
  🎮 Valorant (234)
  🎮 League (892)
  🎮 Apex (156)
```

---

### **🟡 PRIORITÉ 2 (nice to have) :**

**5. Filtres**
```
- Par rank
- Par région  
- Par tags
```

**6. Migration Bulma**
```
Actuellement: Design custom
Option: Migrer vers Bulma pour UI plus propre
```

**7. Helper pour noms jeux**
```
Afficher "League of Legends" au lieu de "/league"
Afficher "Valorant" au lieu de "/valorant"
```

---

### **🟢 PRIORITÉ 3 (post-MVP) :**

**8. Auth amélioré**
```
- Logout
- Profile page
- Settings
```

**9. PWA setup**
```
- manifest.json
- Install sur home screen
```

**10. Internationalisation FR/EN**
```
- Feeds séparés
- Language column
```

---

## **PLAN D'ACTION POUR FINIR MVP :**

**Session 1 (2-3h) : Pages rooms**
```elixir
# GET /valorant
# GET /league  
# GET /apex

GameController + templates
```

**Session 2 (1-2h) : Boutons fonctionnels**
```javascript
// Upvote
// Interested
// Comments

AJAX calls vers backend
```

**Session 3 (1h) : Sidebar dynamique**
```html
<!-- Liste jeux avec counts -->
```

**Session 4 (1h) : Discord display**
```html
<!-- Afficher Discord dans cards -->
```

**Session 5 (1h) : Polish & tests**
```
- Fix bugs
- Responsive mobile
- Performance
```

---

## **ESTIMATION TEMPS TOTAL RESTANT :**

**6-8 heures de dev = MVP COMPLET ! 🚀**

**Soit 2-3 jours de travail concentré !**

---

**Qu'est-ce qu'on attaque en premier ?** 

**Je suggère : Pages rooms (`/valorant`, `/league`) → c'est le cœur du produit ! 💯**