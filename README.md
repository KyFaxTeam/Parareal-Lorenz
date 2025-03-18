# Simulation du système de Lorenz modifié pour une particule active

Ce projet consiste à simuler et visualiser le comportement d'une particule active guidée par sa mémoire, modélisée par un système de Lorenz adapté. Il comprend un programme Fortran pour la simulation numérique et un script Python pour la visualisation des résultats.

## Le système d'équations

Le système d'équations différentielles ordinaires (EDO) à résoudre est le suivant :


$\dot{X} = Y - X$
$\dot{Y} = -\frac{1}{\tau} Y + X Z$
$\dot{Z} = R - \frac{1}{\tau} Z - X Y$


Où :
- X : Vitesse horizontale de la particule
- Y : Force de mémoire d'onde
- Z : Hauteur du champ d'onde à la position de la particule
- τ : Paramètre de mémoire
- R : Amplitude adimensionnée des ondes générées (fixé à 1.0)

## Installation

### Prérequis

- Compilateur Fortran avec support MPI (mpif90)
- Python 3.6+ avec numpy et matplotlib
- Implementation MPI (comme OpenMPI ou MPICH)

### Compilation du programme Fortran

Le projet utilise un Makefile pour faciliter la compilation :

```bash
# Compiler le programme
make
```

### Configuration de l'environnement Python

Pour installer les dépendances Python nécessaires, il est recommandé de créer un environnement virtuel :

```bash
# Création de l'environnement virtuel
python -m venv lorenz_env

# Activation de l'environnement virtuel
# Sur Linux/Mac
source lorenz_env/bin/activate
# Sur Windows
lorenz_env\Scripts\activate

# Installation des dépendances
pip install numpy matplotlib

# Pour désactiver l'environnement lorsque vous avez terminé
deactivate
```

## Utilisation du programme

### Méthodes de résolution disponibles

Le programme propose deux méthodes pour résoudre le système:

1. **RK4** : Méthode classique de Runge-Kutta d'ordre 4 (séquentielle)
2. **Parareal** : Algorithme de parallélisation temporelle avec MPI

### Simulation avec RK4 (séquentiel)

```bash
# Format: ./lorenz_solver rk4 tau h tf X0 Y0 Z0
./lorenz_solver rk4 5.0 0.01 100.0 1.0 0.0 0.0
```

Ou via le Makefile:

```bash
make run_rk4
```

### Simulation avec Parareal (parallèle)

```bash
# Format: mpirun -np N ./lorenz_solver parareal tau h_coarse h_fine tf X0 Y0 Z0
mpirun -np 4 ./lorenz_solver parareal 5.0 0.1 0.01 100.0 1.0 0.0 0.0
```

Où:
- `N` est le nombre de processus MPI à utiliser
- `h_coarse` est le pas de temps pour l'approximation grossière
- `h_fine` est le pas de temps pour l'approximation fine

Ou via le Makefile:

```bash
make run_parareal
```

### Tests avec différentes valeurs de tau

```bash
# Exécuter plusieurs simulations RK4 avec différentes valeurs de tau
make test_rk4

# Exécuter plusieurs simulations Parareal avec différentes valeurs de tau
make test_parareal
```

### Benchmarking des performances

```bash
# Comparer les performances entre RK4 et Parareal
make benchmark
```

### Visualisation avec le script Python

Pour visualiser les résultats de simulation :

```bash
# Activer l'environnement virtuel si ce n'est pas déjà fait
source lorenz_env/bin/activate

# Lancer le script de visualisation
python plotter.py
```

Le script offre quatre options :
1. Analyser un fichier spécifique avec plusieurs types de visualisations
2. Analyser tous les fichiers de sortie
3. Comparer RK4 et Parareal pour une valeur de tau spécifique
4. Comparer RK4 et Parareal pour toutes les valeurs de tau disponibles

## Scénarios disponibles

Le programme intègre 4 scénarios prédéfinis avec différentes valeurs du paramètre τ :

1. **Type 1 (État non-marcheur)**: τ = 0.5
   - Comportement attendu: Convergence vers X = 0

2. **Type 2 (Marche régulière)**: τ = 2.0
   - Comportement attendu: X constant non nul

3. **Type 3 (Marche chaotique)**: τ = 5.0
   - Comportement attendu: Oscillations imprévisibles

4. **Type 4 (Oscillations avec dérive)**: τ = 8.9
   - Comportement attendu: Oscillations avec tendance

### Exécuter des scénarios spécifiques

Vous pouvez facilement exécuter chaque scénario via le Makefile:

```bash
# Scénarios avec RK4 (séquentiel)
make scenario1_rk4    # État non-marcheur (τ = 0.5)
make scenario2_rk4    # Marche régulière (τ = 2.0)
make scenario3_rk4    # Marche chaotique (τ = 5.0)
make scenario4_rk4    # Oscillations avec dérive (τ = 8.9)
make all_scenarios_rk4  # Tous les scénarios avec RK4

# Scénarios avec Parareal (parallèle)
make scenario1_parareal  # État non-marcheur avec Parareal
make scenario2_parareal  # Marche régulière avec Parareal
make scenario3_parareal  # Marche chaotique avec Parareal
make scenario4_parareal  # Oscillations avec dérive avec Parareal
make all_scenarios_parareal  # Tous les scénarios avec Parareal
```

## Structure du projet

- **main.f90**: Programme principal qui coordonne les méthodes
- **rk4_solver.f90**: Module implémentant la méthode RK4
- **parareal_solver.f90**: Module implémentant l'algorithme Parareal avec MPI
- **domain_decomposition.f90**: Module pour diviser le domaine temporel en sous-intervalles
- **derivatives.f90**: Module contenant les équations du système Lorenz
- **param.f90**: Module contenant les paramètres prédéfinis
- **plotter.py**: Script Python pour la visualisation et comparaison des résultats
- **Makefile**: Facilite la compilation et l'exécution
- **output/**: Dossier contenant les fichiers de sortie générés

## Nettoyage

```bash
# Supprimer les fichiers objets et exécutables
make clean

# Supprimer également les fichiers de données et graphiques
make distclean
```

## Notes sur la parallélisation avec Parareal

L'algorithme Parareal permet de paralléliser l'intégration temporelle d'EDOs en divisant l'intervalle de temps en sous-intervalles qui peuvent être traités simultanément. La méthode utilise:

1. Un propagateur grossier (G) rapide mais imprécis (ici: méthode d'Euler)
2. Un propagateur fin (F) précis mais coûteux (ici: RK4)
3. Une correction itérative qui combine les deux propagateurs

L'algorithme converge après quelques itérations, avec une accélération potentielle qui dépend du nombre de processus, de la taille du problème, et du taux de convergence.

## Side-by-Side Comparison of RK4 and Parareal
## Comparaison côte à côte de RK4 et Parareal

Ce projet inclut maintenant des outils pour une comparaison détaillée côte à côte des méthodes RK4 et Parareal. Ces comparaisons aident à visualiser les différences numériques entre les méthodes et à analyser leur précision relative.

### Exécuter des comparaisons

Vous pouvez exécuter des comparaisons de deux façons:

1. **En utilisant les cibles du Makefile**:
```bash
# Comparer des scénarios spécifiques
make compare_scenario1  # Non-marcheur (tau=0.5)
make compare_scenario2  # Marcheur régulier (tau=2.0)
make compare_scenario3  # Marcheur chaotique (tau=5.0)
make compare_scenario4  # Oscillations avec dérive (tau=8.9)

# Exécuter tous les scénarios de comparaison
make compare_all
```

2. **En utilisant directement le script plotter**:
```bash
# Comparer une valeur tau spécifique
python plotter.py compare --tau=5.0 --output=output/custom_comparison

# Exécuter une analyse complète de toutes les valeurs tau disponibles
python plotter.py analysis
```

### Fonctionnalités de comparaison

La boîte à outils de comparaison fournit:

1. **Évolution temporelle côte à côte**: Graphiques des variables X, Y et Z au fil du temps pour les deux méthodes
2. **Analyse d'erreur**: Calcul de l'erreur absolue maximale et de l'erreur de norme L2 pour chaque variable
3. **Portraits de phase**: Comparaison des portraits de phase dans les plans X-Y, X-Z et Y-Z
4. **Visualisation de trajectoire 3D**: Graphiques 3D de la trajectoire complète pour les deux méthodes
5. **Statistiques récapitulatives**: Métriques de comparaison quantitatives entre les deux méthodes

### Analyse d'erreur

L'analyse d'erreur compare la solution RK4 (considérée comme référence) avec la solution Parareal. Comme Parareal produit généralement moins de points de sortie, une interpolation cubique est utilisée pour faire correspondre les points temporels pour la comparaison.

Les métriques d'erreur incluent:
- **Erreur absolue maximale**: La plus grande différence entre les solutions RK4 et Parareal
- **Erreur de norme L2**: L'erreur quadratique moyenne sur tous les points temporels

### Fichiers de sortie

Les résultats de comparaison sont enregistrés dans le répertoire `output/comparisons/` avec les fichiers suivants:
- `comparison_tau<valeur>_comparison.png`: Graphiques de comparaison principaux
- `comparison_tau<valeur>_phase_portraits.png`: Comparaisons de portraits de phase
- `error_vs_tau.png`: Graphique récapitulatif montrant comment l'erreur varie avec le paramètre tau

