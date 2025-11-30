defmodule MyApp.Controllers.OnboardingController do
  use Plug.Router

  # Routes:
  # GET  /onboarding           → redirect to step1
  # GET  /onboarding/step1     → step1 (formulaire email/password)
  # POST /onboarding/step1     → process step1, redirect to step2
  # GET  /onboarding/step2     → step2 (formulaire company info)
  # POST /onboarding/step2     → process step2, redirect to step3
  # GET  /onboarding/step3     → step3 (formulaire linktree config)
  # POST /onboarding/step3     → process step3, finalize & redirect to dashboard

  # Assurez-vous d'avoir Plug.Session configuré
  plug Plug.Session,
    store: :cookie,
    key: "onboarding_session",
    signing_salt: "some_signing_salt_here"

  plug :match
  plug :dispatch

  # --- Route principale (Redirection vers la première étape) ---
  # Gère l'accès à /onboarding (la racine du scope)
  get "/" do
    conn
    |> put_resp_header("location", "/onboarding/step1") # Redirection vers /onboarding/step1
    |> send_resp(302, "")
  end

  # ----------------------------------------------------------------
  # ÉTAPE 1: Informations de l'utilisateur (Email, Mot de passe)
  # ----------------------------------------------------------------

  get "/step1" do # Chemin: /onboarding/step1
    data = get_session(conn, :onboarding_data) || %{}
    error_msg = nil

    html = EEx.eval_file("lib/my_app/templates/onboarding/step1_info.html.eex",
      assigns: %{
        data: data,
        error_msg: error_msg
      }
    )

    send_resp(conn, 200, html)
  end

  post "/step1" do # Chemin: /onboarding/step1
    params = conn.params
    data = get_session(conn, :onboarding_data) || %{}

    # Stockage des données
    new_data = Map.merge(data, %{email: params["email"], password: params["password"]})

    # Passe à l'étape 2
    conn
    |> put_session(:onboarding_data, new_data)
    |> put_resp_header("location", "/onboarding/step2") # Redirection vers /onboarding/step2
    |> send_resp(302, "")
  end

  # ----------------------------------------------------------------
  # ÉTAPE 2: Informations de l'entreprise (Nom, Taille)
  # ----------------------------------------------------------------

  get "/step2" do # Chemin: /onboarding/step2
    data = get_session(conn, :onboarding_data) || %{}
    error_msg = nil

    html = EEx.eval_file("lib/my_app/templates/onboarding/step2_info.html.eex",
      assigns: %{
        data: data,
        error_msg: error_msg
      }
    )
    send_resp(conn, 200, html)
  end

  post "/step2" do # Chemin: /onboarding/step2
    params = conn.params
    data = get_session(conn, :onboarding_data) || %{}

    # Stockage des données
    new_data = Map.merge(data, %{company_name: params["company_name"], company_size: params["company_size"]})

    # Passe à l'étape 3
    conn
    |> put_session(:onboarding_data, new_data)
    |> put_resp_header("location", "/onboarding/step3") # Redirection vers /onboarding/step3
    |> send_resp(302, "")
  end

  # ----------------------------------------------------------------
  # ÉTAPE 3: Configuration du Linktree (Slug, Thème) - FINALISATION
  # ----------------------------------------------------------------

  get "/step3" do # Chemin: /onboarding/step3
    data = get_session(conn, :onboarding_data) || %{}
    error_msg = nil

    html = EEx.eval_file("lib/my_app/templates/onboarding/step3_info.html.eex",
      assigns: %{
        data: data,
        error_msg: error_msg
      }
    )
    send_resp(conn, 200, html)
  end

  post "/step3" do # Chemin: /onboarding/step3
    params = conn.params
    data = get_session(conn, :onboarding_data) || %{}

    # Finalisation des données
    final_data = Map.merge(data, %{linktree_slug: params["linktree_slug"], initial_theme: params["initial_theme"]})

    # --------------------------------------------------------------------------
    # --- LOGIQUE DE PERSISTANCE ET FINALISATION ---
    # Ici, nous devons appeler les services pour sauvegarder les données
    # dans la base de données (User, Company, Linktree).
    # --------------------------------------------------------------------------

    # # Exemple du code qui devra être implémenté plus tard :
    # case MyApp.Services.Onboarding.run(final_data) do
    #   {:ok, user} ->
    #     # La persistance a réussi, utiliser 'user' pour la session
    #     conn
    #     |> put_session(:user_id, user.id)
    #     |> put_session(:user_email, user.email)
    #     |> delete_session(:onboarding_data)
    #     |> put_resp_header("location", "/dashboard")
    #     |> send_resp(302, "")
    #   {:error, msg} ->
    #     # La persistance a échoué (erreur DB, etc.)
    #     conn
    #     |> delete_session(:onboarding_data)
    #     |> put_session(:error_msg, "Erreur critique de finalisation. Veuillez recommencer : #{msg}")
    #     |> put_resp_header("location", "/step1") # Redirection vers /onboarding/step1
    #     |> send_resp(302, "")
    # end

    # --------------------------------------------------------------------------
    # --- SIMULATION DE SUCCÈS POUR LE MOMENT ---
    # Nous simulons la création et la connexion de l'utilisateur.
    # --------------------------------------------------------------------------

    # Création d'un ID utilisateur factice
    user_id = :rand.uniform(1_000_000)

    # Succès simulé : on nettoie les données et on connecte l'utilisateur
    conn
    |> put_session(:user_id, user_id)
    |> put_session(:user_email, final_data.email)
    |> delete_session(:onboarding_data) # Nettoyage des données temporaires
    |> put_resp_header("location", "/dashboard") # Redirection vers le dashboard
    |> send_resp(302, "")
  end
end
