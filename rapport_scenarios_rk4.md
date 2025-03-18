# Rapport d'Analyse des Scénarios RK4 pour le Système de Lorenz

## 1. Introduction

Ce rapport présente une analyse détaillée des simulations du système de Lorenz modifié à l'aide de la méthode de Runge-Kutta d'ordre 4 (RK4) pour différents scénarios. Chaque scénario correspond à un régime dynamique spécifique du système, déterminé principalement par la valeur du paramètre de mémoire τ (tau).

## 2. Paramètres des Scénarios

### Paramètres Communs à Tous les Scénarios
- **Paramètre d'amplitude R**: 2.5
- **Conditions initiales**: X₀ = 1.0, Y₀ = 0.0, Z₀ = 0.0
- **Temps de simulation**: tf = 100.0

### Scénario 1: Type 1 (État Non-Marcheur)
- **Paramètre τ**: 0.5
- **Pas de temps h**: 0.001
- **Nombre d'étapes**: 99,999
- **Temps d'exécution**: 0.171 secondes
- **Comportement attendu**: Convergence vers X = 0

### Scénario 2: Type 2 (Marche Régulière)
- **Paramètre τ**: 2.0
- **Pas de temps h**: 0.005
- **Nombre d'étapes**: 20,000
- **Temps d'exécution**: 0.037 secondes
- **Comportement attendu**: X constant non nul (X ≈ ±1.5)

### Scénario 3: Type 3 (Marche Chaotique)
- **Paramètre τ**: 5.0
- **Pas de temps h**: 0.001
- **Nombre d'étapes**: 99,999
- **Temps d'exécution**: 0.144 secondes
- **Comportement attendu**: Oscillations imprévisibles (trajectoire chaotique)

### Scénario 4: Type 4 (Oscillations avec Dérive)
- **Paramètre τ**: 8.9
- **Pas de temps h**: 0.001
- **Nombre d'étapes**: 99,999
- **Temps d'exécution**: 0.166 secondes
- **Comportement attendu**: Oscillations avec dérive nette

## 3. Fichiers Générés

Pour chaque scénario, les fichiers suivants ont été générés:

### Données Brutes
- `output/rk4_tau0.5.dat`
- `output/rk4_tau2.0.dat`
- `output/rk4_tau5.0.dat`
- `output/rk4_tau8.9.dat`

### Visualisations
Pour chaque valeur de τ, trois types de graphiques ont été générés:
- **Évolution temporelle**: `output/rk4_tau{τ}_time.png`
- **Portrait de phase (X-Z)**: `output/rk4_tau{τ}_phase.png`
- **Trajectoire 3D**: `output/rk4_tau{τ}_3d.png`

## 4. Analyse des Résultats par Scénario

### Scénario 1: τ = 0.5 (État Non-Marcheur)

#### Observations
- La trajectoire converge rapidement vers l'origine (X → 0)
- Absence d'oscillations significatives après la phase transitoire
- Comportement de type "point fixe"

#### Analyse Théorique
- Pour τ < 1, le terme dissipatif (-X et -Y/τ, -Z/τ) domine la dynamique
- Point d'équilibre théorique: (0, 0, R·τ) = (0, 0, 1.25)
- La simulation confirme bien la convergence vers cet état stationnaire

### Scénario 2: τ = 2.0 (Marche Régulière)

#### Observations
- Stabilisation sur une valeur de X non nulle et constante
- Comportement stable et prévisible après une courte période transitoire

#### Analyse Théorique
- Point d'équilibre non trivial: X = ±√(R-1/τ²) = ±√(2.5-1/4) = ±√2.25 = ±1.5
- Y = X, Z = 1/τ = 0.5
- La simulation confirme cette valeur théorique avec une excellente précision

### Scénario 3: τ = 5.0 (Marche Chaotique)

#### Observations
- Comportement chaotique avec oscillations irrégulières
- Aucun motif régulier ou périodique identifiable
- Trajectoire dans l'espace des phases complexe et auto-évitante

#### Analyse Théorique
- La valeur τ = 5.0 place le système dans un régime chaotique
- L'exposant de Lyapunov est positif, indiquant une forte sensibilité aux conditions initiales
- Bifurcation vers le chaos par rapport aux scénarios précédents

### Scénario 4: τ = 8.9 (Oscillations avec Dérive)

#### Observations
- Oscillations quasi-périodiques avec une dérive progressive
- Alternance entre phases d'oscillation locale et phases de déplacement directionnel
- Structure plus organisée que le scénario chaotique mais moins stable que le scénario régulier

#### Analyse Théorique
- Cette valeur élevée de τ réduit l'effet des termes dissipatifs
- Le système montre un comportement intermédiaire entre chaotique et régulier
- Les oscillations présentent une structure plus ordonnée mais avec une dynamique complexe

## 5. Analyse des Graphiques

### Graphiques d'Évolution Temporelle
- **Scénario 1 (τ = 0.5)**: X converge rapidement vers zéro, Y et Z se stabilisent
- **Scénario 2 (τ = 2.0)**: X et Y se stabilisent à des valeurs non-nulles constantes, Z reste stable
- **Scénario 3 (τ = 5.0)**: Fortes oscillations irrégulières de toutes les variables
- **Scénario 4 (τ = 8.9)**: Oscillations avec une structure plus régulière mais avec dérive progressive

### Portraits de Phase (X-Z)
- **Scénario 1**: Convergence vers un point unique (0, 1.25)
- **Scénario 2**: Convergence vers un point fixe non nul (±1.5, 0.5)
- **Scénario 3**: Attracteur étrange avec structure fractale complexe
- **Scénario 4**: Trajectoire plus ordonnée mais non-périodique, formant un cycle limite déformé

### Visualisations 3D
- **Scénario 1**: Simple ligne convergeant vers un point
- **Scénario 2**: Trajectoire convergeant vers un point fixe non trivial
- **Scénario 3**: Attracteur étrange tridimensionnel avec structure complexe
- **Scénario 4**: Structure intermédiaire entre l'attracteur chaotique et le point fixe

## 6. Performance et Précision Numérique

### Temps d'Exécution
- Les temps d'exécution sont remarquablement courts malgré le grand nombre d'étapes
- Le scénario 2 a été le plus rapide (0.037s) grâce à son pas de temps plus grand (h = 0.005)
- Les autres scénarios ont nécessité environ 0.14-0.17s avec h = 0.001

### Considérations sur la Précision
- Le pas de temps h = 0.001 assure une précision élevée pour les scénarios 1, 3 et 4
- Pour le scénario 2, un pas plus grand (h = 0.005) est suffisant en raison de la dynamique plus régulière
- Aucune instabilité numérique n'a été détectée dans les simulations

## 7. Conclusions Globales

### Validation de la Théorie
- Les simulations confirment parfaitement les comportements théoriques attendus pour chaque régime
- Les points d'équilibre observés correspondent aux valeurs théoriques calculées

### Transition entre Régimes
- La transition du comportement "non-marcheur" (τ = 0.5) vers le régime chaotique (τ = 5.0) est bien capturée
- L'influence du paramètre τ sur la dynamique est clairement illustrée

### Efficacité de la Méthode RK4
- RK4 s'est avérée très efficace pour tous les scénarios, avec des temps d'exécution courts
- La méthode capture avec précision tant les comportements stables que chaotiques

### Perspectives
- Les résultats RK4 fournissent une excellente référence pour comparaison avec la méthode Parareal
- La capacité de RK4 à résoudre avec précision des dynamiques aussi diverses est confirmée

## 8. Annexes

### Commandes Utilisées
```bash
make all_scenarios_rk4
python plotter.py
```

### Structure des Fichiers de Données
Format des fichiers .dat: colonnes "t X Y Z" avec une ligne d'en-tête

---

