# Investigation Numérique des Régimes Dynamiques du Modèle de Lorenz pour une Particule Active à Mémoire (F=0)

## Description

Ce projet réalise une investigation numérique du modèle de Lorenz modifié décrivant une particule active à mémoire, tel que présenté par Valani et Dandogbessi [1]. L'objectif est d'étudier l'influence du paramètre d'amplitude `R` sur le comportement dynamique asymptotique (vitesse moyenne `<X>`) et d'analyser la sensibilité aux conditions initiales ainsi que la multistabilité, en suivant la méthodologie décrite dans `project.md` et `algorithme.md`.

Le code principal est écrit en Fortran pour l'intégration numérique (utilisant RK4) et un script Python est fourni pour visualiser les résultats.

[1] R. N. Valani and B. S. Dandogbessi, *Asymmetric limit cycles within Lorenz chaos induce anomalous mobility for a memory-driven active particle*, Phys. Rev. E **110**, L052203 (2024).

## Structure des Fichiers

*   `project.md`: Description détaillée du projet, des objectifs et de la méthodologie.
*   `algorithme.md`: Algorithme pas-à-pas implémenté dans le code Fortran.
*   `parameters.f90`: Module Fortran définissant les paramètres physiques et numériques de la simulation.
*   `derivatives.f90`: Module Fortran définissant les équations différentielles du système.
*   `rk4_solver.f90`: Module Fortran implémentant l'algorithme Runge-Kutta d'ordre 4, incluant une fonction spécifique pour calculer la moyenne temporelle de X.
*   `main_lorenz_scan.f90`: Programme principal Fortran qui orchestre la simulation (boucles sur R et les conditions initiales), appelle le solveur et écrit les résultats.
*   `visualize_results.py`: Script Python pour charger les résultats de la simulation et générer les graphiques (diagramme de bifurcation, statistiques d'ensemble, histogrammes).
*   `lorenz_scan.exe` (après compilation): Exécutable du programme de simulation Fortran.
*   `lorenz_scan_results.csv` (après exécution): Fichier CSV contenant les résultats de la simulation (R, <X>_R, sigma_X(R), et tous les <X>_j).
*   `plots/` (après visualisation): Répertoire contenant les graphiques générés par le script Python.
*   `README.md`: Ce fichier.

## Dépendances

*   **Fortran:** Un compilateur Fortran (par exemple, `gfortran`) est nécessaire pour compiler le code source.
*   **Python:** Python 3.x est requis pour exécuter le script de visualisation.
*   **Bibliothèques Python:** Les bibliothèques suivantes sont nécessaires (peuvent être installées via pip) :
    *   `pandas`
    *   `numpy`
    *   `matplotlib`
    ```bash
    pip install pandas numpy matplotlib
    ```

## Compilation et Utilisation (Makefile)

Ce projet utilise un `Makefile` pour simplifier la compilation, l'exécution et le nettoyage. Assurez-vous d'avoir `make` et un compilateur Fortran (comme `gfortran`) installés et accessibles depuis votre terminal.

Ouvrez un terminal dans le répertoire du projet et utilisez les commandes suivantes :

*   **Compiler le code Fortran :**
    ```bash
    make
    ```
    ou
    ```bash
    make all
    ```
    Ceci compile les fichiers source Fortran (`.f90`) en fichiers objets (`.o`) puis les lie pour créer l'exécutable `lorenz_scan.exe`.

*   **Exécuter la simulation :**
    ```bash
    make run
    ```
    Ceci compile le code si nécessaire, puis lance `./lorenz_scan.exe` (ou `.\lorenz_scan.exe` sur Windows). Le programme affichera la progression et créera `lorenz_scan_results.csv`.

*   **Générer les graphiques (après l'exécution) :**
    ```bash
    make plot
    ```
    Ceci exécute le script `visualize_results.py` qui lit `lorenz_scan_results.csv` et sauvegarde les graphiques dans le répertoire `plots/`. Nécessite Python et les bibliothèques listées dans les dépendances.

*   **Nettoyer les fichiers générés :**
    ```bash
    make clean
    ```
    Ceci supprime l'exécutable, les fichiers objets (`.o`), les fichiers modules (`.mod`), le fichier de résultats (`.csv`) et le répertoire `plots/`.

*   **Afficher l'aide :**
    ```bash
    make help
    ```
    Ceci affiche un résumé des cibles disponibles dans le Makefile.

## Exécution de la Simulation (via Makefile)

La méthode recommandée pour exécuter la simulation est d'utiliser le Makefile :

```bash
make run
```

Ceci s'assurera que le code est compilé avant de lancer l'exécutable. Le programme affichera la progression dans le terminal et générera le fichier `lorenz_scan_results.csv`. La durée d'exécution dépendra des paramètres définis dans `parameters.f90` et des performances de votre machine.

## Visualisation des Résultats (via Makefile)

Après l'exécution de la simulation (`make run`), utilisez la commande suivante pour générer les graphiques :

```bash
make plot
```

Ceci exécutera le script `visualize_results.py`. Le script lira le fichier `lorenz_scan_results.csv`, générera les graphiques décrits dans `algorithme.md` (Étape 7), et les sauvegardera dans le répertoire `plots/`.

## Sortie

*   **`lorenz_scan_results.csv`**: Fichier de données contenant :
    *   `R`: La valeur du paramètre R.
    *   `Avg_X_Ensemble`: La moyenne `<X>_R` calculée sur les `N_IC` conditions initiales valides pour ce R.
    *   `StdDev_X_Ensemble`: L'écart-type `sigma_X(R)` des `<X>_j` valides pour ce R.
    *   `Avg_X_1`, `Avg_X_2`, ..., `Avg_X_N_IC`: Les moyennes temporelles individuelles `<X>_j` pour chaque condition initiale. Les simulations échouées (instabilité) sont marquées par une très grande valeur (proche de `HUGE` en Fortran).
*   **`plots/`**: Répertoire contenant les fichiers image (`.png`) :
    *   `bifurcation_plot.png`: Diagramme de bifurcation montrant tous les `<X>_j` en fonction de R.
    *   `ensemble_stats_plot.png`: Graphique de `<X>_R` et `sigma_X(R)` en fonction de R.
    *   `histogram_R_xxx.png`: Histogrammes de la distribution des `<X>_j` pour des valeurs spécifiques de R.