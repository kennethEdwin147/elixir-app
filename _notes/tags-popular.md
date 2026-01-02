**OK! Voici la note pour plus tard:**

---

## 📝 TODO: Tags Populaires Dynamiques

**Idée:** Afficher les tags les plus utilisés dans les suggestions (au lieu de hardcodés).

**Exemple visuel:**
```
Suggestions populaires (basé sur 1247 posts):
ranked (542) | mic (421) | chill (389) | duelist (287) | fr (198)...
```

### Implementation:

**1. PostService.popular_tags/2**
```elixir
def popular_tags(game \\ "valorant", limit \\ 16) do
  posts = Repo.all(
    from p in Post,
    where: p.game == ^game and not is_nil(p.tags),
    select: p.tags
  )
  
  posts
  |> Enum.flat_map(fn tags_json ->
    case Jason.decode(tags_json) do
      {:ok, tags} -> tags
      _ -> []
    end
  end)
  |> Enum.frequencies()
  |> Enum.sort_by(fn {_tag, count} -> count end, :desc)
  |> Enum.take(limit)
  # Retourne: [{"ranked", 542}, {"mic", 421}, ...]
end
```

**2. Controller - Passe au template**
```elixir
popular_tags = PostService.popular_tag_names("valorant", 16)
# assigns: %{popular_tags: popular_tags}
```

**3. Tag-selector - Accept suggestions attr**
```html
<tag-selector 
  name="tags" 
  suggestions='<%= Jason.encode!(@popular_tags) %>'>
</tag-selector>
```

**Avantages:**
- Tags évoluent avec l'usage
- Suggère ce que les users utilisent vraiment
- Meta/Analytics inclus

**Timing:** Phase 2, après avoir ~100+ posts

---

**Sauvegarde ça quelque part!** 📋