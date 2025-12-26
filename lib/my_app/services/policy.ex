defmodule MyApp.Services.Policy do
# =============================================================================
# Policy - Gestion des permissions et ownership
# =============================================================================
# Centralise toute la logique d'autorisation (qui peut faire quoi).
#
# Usage dans les controllers:
#   if Policy.can_delete_post?(current_user, post) do
#     PostService.delete(post.id)
#   else
#     send_resp(403, "Non autorisé")
#   end
#
# Avantages:
#   - Logique centralisée (un seul endroit à modifier)
#   - Facilement extensible (ajout de rôles admin/mod)
#   - Code controllers propre et lisible
# =============================================================================


  def can_create_post?(user) do
    user != nil
  end

  def can_edit_post?(user, post) do
    user && user.id == post.user_id
  end

  def can_delete_post?(user, post) do
    user && user.id == post.user_id
  end

  def can_comment?(user) do
    user != nil
  end

  def can_delete_comment?(user, comment) do
    user && user.id == comment.user_id
  end
end
