defmodule MyApp.Services.Policy do
  @moduledoc """
  Policy - Gestion des permissions et ownership.
  Centralise toute la logique d'autorisation (qui peut faire quoi).

  Usage dans les controllers:
    if Policy.can_edit_profile?(current_user, profile) do
      Profile.update_profile(profile.id, attrs)
    else
      send_resp(403, "Non autorisé")
    end

  Avantages:
    - Logique centralisée (un seul endroit à modifier)
    - Facilement extensible (ajout de rôles admin/mod)
    - Code controllers propre et lisible

  ## Policies disponibles

  ### Profiles
  - can_create_profile?(user)
  - can_edit_profile?(user, profile)
  - can_delete_profile?(user, profile)
  - can_view_profile?(user, profile)

  ### Connexions
  - can_send_request?(user, target_user)
  - can_accept_request?(user, request)
  - can_decline_request?(user, request)
  - can_cancel_request?(user, request)
  - can_delete_connection?(user, connection, other_user_id)

  ### Administration
  - is_admin?(user)
  - is_premium?(user)
  """

  # ============================================================================
  # PROFILES
  # ============================================================================

  @doc """
  Un user connecté peut créer un profile.
  """
  def can_create_profile?(user) do
    user != nil
  end

  @doc """
  Un user peut éditer uniquement son propre profile.
  """
  def can_edit_profile?(user, profile) do
    user && user.id == profile.user_id
  end

  @doc """
  Un user peut supprimer uniquement son propre profile.
  """
  def can_delete_profile?(user, profile) do
    user && user.id == profile.user_id
  end

  @doc """
  Tout le monde peut voir un profile actif.
  Un user peut voir ses propres profiles même inactifs.
  """
  def can_view_profile?(user, profile) do
    profile.active || (user && user.id == profile.user_id)
  end

  # ============================================================================
  # CONNECTION REQUESTS
  # ============================================================================

  @doc """
  Un user connecté peut envoyer une demande à un autre user.
  """
  def can_send_request?(user, target_user) do
    user && target_user && user.id != target_user.id
  end

  @doc """
  Seul le target (destinataire) peut accepter une demande.
  """
  def can_accept_request?(user, request) do
    user && user.id == request.target_id
  end

  @doc """
  Seul le target (destinataire) peut refuser une demande.
  """
  def can_decline_request?(user, request) do
    user && user.id == request.target_id
  end

  @doc """
  Seul le requester (envoyeur) peut annuler sa demande.
  """
  def can_cancel_request?(user, request) do
    user && user.id == request.requester_id && request.status == "pending"
  end

  # ============================================================================
  # CONNECTIONS
  # ============================================================================

  @doc """
  Un user peut supprimer une connexion s'il est l'un des deux participants.
  """
  def can_delete_connection?(user, connection, other_user_id) do
    user && (user.id == connection.user_id_1 || user.id == connection.user_id_2) &&
      (other_user_id == connection.user_id_1 || other_user_id == connection.user_id_2)
  end

  # ============================================================================
  # ADMINISTRATION & PREMIUM
  # ============================================================================

  @doc """
  Vérifie si un user est admin (future feature).
  """
  def is_admin?(_user) do
    # TODO: Ajouter champ role à la table users
    false
  end

  @doc """
  Vérifie si un user a un compte premium.
  """
  def is_premium?(user) do
    user && user.is_premium == true
  end
end
