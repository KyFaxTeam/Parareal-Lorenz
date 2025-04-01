

---

**Document de Projet : Investigation Numérique des Régimes Dynamiques et de la Multistabilité du Modèle de Lorenz pour une Particule Active à Mémoire**

**1. Introduction**

Le comportement des systèmes hors équilibre soumis à des forces externes, comme les particules actives, peut être **profondément contre-intuitif**. Un exemple frappant est la **mobilité négative**, où un système répond à un biais par une dérive nette *dans la direction opposée*. Récemment, **Valani et Dandogbessi** [1] ont étudié un modèle minimal de particule active auto-propulsée guidée par sa propre mémoire d'onde. Ils ont démontré que l'équation de trajectoire, dans une configuration idéalisée (onde cosinusoïdale), se réduit au **célèbre système de Lorenz** [2] en l'absence de biais externe (`F=0`). En analysant ce système avec un petit biais `F`, ils ont identifié un mécanisme dynamique remarquable, basé sur la **séparation de cycles limites asymétriques coexistants** émergeant du chaos de Lorenz, pouvant conduire simultanément à une **mobilité négative géante** (GNM) et une **mobilité positive géante** (GPM).

Le présent projet vise à approfondir l'investigation numérique de ce modèle spécifique (équivalent à Lorenz pour `F=0`), en se concentrant sur la caractérisation fine des régimes dynamiques et de la multistabilité en fonction d'un paramètre clé du système (`R`), et en évaluant rigoureusement la robustesse des observations par rapport aux conditions initiales, conformément aux standards de l'étude des systèmes chaotiques.

**2. Objectifs**

Les principaux objectifs de cette étude numérique sont :

1.  **Caractériser l'influence du paramètre `R`** (amplitude adimensionnelle de l'onde) sur le comportement dynamique asymptotique de la particule active (pour `F=0`), notamment sur sa vitesse moyenne `<X>`.
2.  **Évaluer la sensibilité des régimes dynamiques aux conditions initiales (CI)** `(X(0), Y(0), Z(0))`, en accord avec la nature potentiellement chaotique et multistable du système.
3.  **Identifier et délimiter précisément les différentes régions de comportement** (repos, marche stationnaire, marche chaotique, oscillations avec dérive nette) dans l'espace du paramètre `R`, en comparant quantitativement avec les résultats de la Fig 3a de [1].
4.  **Détecter, visualiser et quantifier la coexistence d'attracteurs (multistabilité)** pour des valeurs données de `R`, en analysant la distribution des comportements asymptotiques issus d'un ensemble de conditions initiales.

**3. Méthodologie Proposée**

Pour atteindre ces objectifs, nous proposons la méthodologie numérique suivante, basée sur les bonnes pratiques reconnues et les spécificités de [1] :

*   **Modèle Mathématique :** Nous utiliserons le système d'équations différentielles ordinaires (Eq. 2 dans [1]) pour `F=0` :
    ```
    Ẋ = Y - X
    Ẏ = -(1/τ)Y + XZ
    Ż = R - (1/τ)Z - XY
    ```
    où `X` est la vitesse de la particule, `Y` la force de mémoire d'onde, `Z` la hauteur du champ d'onde, `R` l'amplitude de l'onde (paramètre de contrôle principal), et `τ` le taux de décroissance de l'onde (mémoire). Pour cette étude, **`τ` sera fixé à une valeur constante `τ = [valeur_choisie]`** (par exemple, `τ=10` pour explorer la région IV de [1]). Pour `F=0`, ce système est équivalent au système de Lorenz [2] avec les paramètres `σ=1` et `b=1/τ` via une transformation affine [1, 37].

*   **Solveur Numérique et Vérification :** Le système sera intégré numériquement en utilisant un algorithme de **Runge-Kutta d'ordre 4 (RK4)** implémenté en Fortran. Un **pas de temps `dt` suffisamment petit (ex: `dt ≤ 0.01`)** sera choisi et sa pertinence sera **vérifiée par des tests de convergence** pour garantir la stabilité et la précision, en particulier dans les régimes chaotiques.

*   **Exploration du Paramètre `R` :** Le paramètre `R` sera varié systématiquement dans un intervalle pertinent, par exemple **`R ∈ [0.5, 3.0]`** (couvrant les régions I à IV de la Fig 3a de [1]), avec une résolution suffisante (**`N_R` points, ex: 100-200**) pour bien délimiter les transitions.

*   **Stratégie Robuste des Conditions Initiales Multiples :** Pour *chaque* valeur de `R` étudiée, afin de gérer la sensibilité aux CI et détecter la multistabilité :
    *   Un ensemble de **`N_IC = 50` conditions initiales distinctes** `(X(0)_j, Y(0)_j, Z(0)_j)` sera généré, en adoptant la méthode spécifique de [1] (Fig 4) pour assurer la comparabilité et la reproductibilité :
        *   `Y(0)_j = 0` et `Z(0)_j = 0` pour toutes les `j`.
        *   `X(0)_j` prendra 50 valeurs **linéairement espacées dans l'intervalle `[-5, 5]`**.
    *   La position initiale `X_d(0)` n'apparaissant pas dans le système dynamique pour `X, Y, Z`, elle n'a pas besoin d'être spécifiée comme CI dynamique.

*   **Protocole de Simulation Individuelle :** Pour chaque couple `(R, CI_j)` :
    *   La simulation sera effectuée sur une durée totale **`T_simulation` longue (ex: 5000 unités de temps**, comme dans [1]) pour permettre au système d'atteindre son régime asymptotique.
    *   La **première moitié de la trajectoire (`T_transient = T_simulation / 2`) sera systématiquement écartée** pour éliminer les effets transitoires, conformément à [1].
    *   La **moyenne temporelle de la vitesse `<X>_j`** sera calculée sur la partie restante de la trajectoire (`T_simulation - T_transient`).

*   **Analyse de la Distribution et de la Multistabilité :** Pour chaque `R` :
    *   Le résultat principal sera la **visualisation de l'ensemble des `N_IC` moyennes temporelles `<X>_j` obtenues**, tracé en fonction de `R`. Ce diagramme de type "bifurcation pour la moyenne" révélera directement les régions de monostabilité (un seul groupe de points `<X>_j` pour un `R` donné) et de multistabilité (plusieurs groupes distincts de points `<X>_j` pour un `R` donné).
    *   La **distribution** des `<X>_j` sera analysée. Des **histogrammes** représentatifs seront générés pour quelques valeurs clés de `R` afin d'illustrer quantitativement la (multi)stabilité.
    *   À titre de mesure globale, la **moyenne d'ensemble `<X>_R = (1/N_IC) * Σ (<X>_j)`** et l'**écart-type `σ_X(R)`** (ou l'étendue min/max) des `<X>_j` seront calculés et tracés en fonction de `R`. L'écart-type quantifiera la dispersion due à la sensibilité aux CI ou à la multistabilité.

*   **Outils Logiciels :** L'intégration numérique sera réalisée en Fortran. L'analyse des données (calculs statistiques, histogrammes) et la génération des graphiques (diagrammes de bifurcation, courbes de moyenne/dispersion, histogrammes, visualisation d'attracteurs) seront effectuées en Python avec les bibliothèques scientifiques standards (NumPy, SciPy, Matplotlib).

**4. Justification et Pertinence de la Méthodologie**

L'utilisation de conditions initiales multiples et l'analyse de la distribution des résultats sont cruciales et constituent une pratique standard pour l'étude de systèmes dynamiques non linéaires comme celui de Lorenz, pour les raisons suivantes :

*   **Nature Chaotique :** Le système de Lorenz est un archétype du chaos [2]. Les systèmes chaotiques exhibent une sensibilité extrême aux conditions initiales. Il est essentiel de vérifier si le comportement moyen à long terme est robuste ou s'il dépend de la CI spécifique, même au sein d'un même attracteur étrange.
*   **Détection de la Multistabilité :** Les systèmes non linéaires peuvent posséder plusieurs états asymptotiques stables (attracteurs) pour les mêmes paramètres [3]. Différentes CI peuvent converger vers différents attracteurs. C'est explicitement le cas dans la Région IV de [1] pour `F=0`. L'exploration systématique avec de multiples CI est la *seule* méthode fiable pour révéler et caractériser cette coexistence.
*   **Caractérisation Représentative :** En présence de multistabilité, visualiser l'ensemble des résultats `<X>_j` donne une image fidèle des comportements possibles. Le calcul de la moyenne d'ensemble `<X>_R` et de l'écart-type fournit des indicateurs synthétiques, l'écart-type mesurant directement l'ampleur de la multistabilité ou de la sensibilité aux CI [3, 4].

**5. Résultats Attendus et Signification**

Cette étude numérique permettra de :

*   Produire un **diagramme de bifurcation détaillé montrant l'ensemble des vitesses moyennes asymptotiques `<X>_j`** en fonction du paramètre `R` (pour `F=0` et la valeur de `τ` choisie).
*   **Confirmer quantitativement et affiner les frontières** entre les différents régimes dynamiques (repos, marche stationnaire ±X, chaos <X>=0, oscillations ±<X>≠0) identifiés qualitativement dans [1].
*   Fournir une **preuve visuelle et quantitative (via la distribution des `<X>_j` et `σ_X(R)`) de la présence, de l'étendue (en `R`) et de la nature de la multistabilité**.
*   **Visualiser les attracteurs correspondants** dans l'espace des phases (ex: projections 2D (X,Z)) pour des valeurs de `R` caractéristiques de chaque régime et de la multistabilité, afin de lier la dynamique observée aux structures géométriques sous-jacentes.
*   Mieux comprendre comment les propriétés intrinsèques (`R`, `τ`) du système actif influencent sa dynamique complexe et ses capacités de transport intrinsèque, jetant des bases solides pour des études futures incluant le biais `F` et l'analyse GNM/GPM.

**6. Références**

[1] R. N. Valani and B. S. Dandogbessi, *Asymmetric limit cycles within Lorenz chaos induce anomalous mobility for a memory-driven active particle*, Phys. Rev. E **110**, L052203 (2024).
[2] E. N. Lorenz, *Deterministic nonperiodic flow*, J. Atmos. Sci. **20**, 130 (1963).
[3] S. H. Strogatz, *Nonlinear Dynamics and Chaos: With Applications to Physics, Biology, Chemistry, and Engineering* (Westview Press, 2015).
[4] C. Sparrow, *The Lorenz Equations: Bifurcations, Chaos, and Strange Attractors* (Springer-Verlag, New York, 1982).
[37] (Référence au Supplemental Material de [1], si pertinent pour la dérivation ou d'autres détails)

---
