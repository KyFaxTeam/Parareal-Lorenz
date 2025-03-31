Votre question est excellente et touche au cœur de la transformation entre l'équation intégro-différentielle initiale et le système d'équations différentielles ordinaires (EDO) de Lorenz. Revenons étape par étape pour clarifier comment on passe de l'intégrale \( F_{\text{self}} \) au système de Lorenz, et comment on pourrait "revenir" à la solution initiale si nécessaire.

---

### Équation initiale

L'équation de départ pour le mouvement d'une particule active guidée par sa mémoire, sans force de biais (\( F = 0 \)), est :

\[
\ddot{x}d + \dot{x}_d = F{\text{self}}
\]

où :

\[
F_{\text{self}} = -R \int_{-\infty}^t W'(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} ds
\]

Dans le cas idéal étudié, \( W(x) = \cos(x) \), donc \( W'(x) = -\sin(x) \), et l'expression devient :

\[
F_{\text{self}} = -R \int_{-\infty}^t (-\sin(x_d(t) - x_d(s))) e^{-\frac{(t - s)}{\tau}} ds = R \int_{-\infty}^t \sin(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} ds
\]

### Transformation en système d'EDO

Pour simplifier cette équation intégro-différentielle, on introduit des variables supplémentaires et on la convertit en un système d'EDO. Voici comment cela se fait :

1. *Définition des variables* :
   - \( X = \dot{x}_d \) : la vitesse horizontale de la particule.
   - \( Y = F_{\text{self}} = R \int_{-\infty}^t \sin(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} ds \) : la force de mémoire d’onde.
   - \( Z = R \int_{-\infty}^t \cos(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} ds \) : la hauteur du champ d’onde à la position de la particule.

2. *Dérivation de l’équation initiale* :
   - Puisque \( \ddot{x}_d = \dot{X} \) et \( \dot{x}_d = X \), l’équation devient :
     \[
     \dot{X} + X = Y
     \]
     donc :
     \[
     \dot{X} = Y - X
     \]
     C’est la première équation du système.

3. *Dérivation des intégrales* :
   - Prenons la dérivée temporelle de \( Y \) :
     \[
     \dot{Y} = \frac{d}{dt} \left( R \int_{-\infty}^t \sin(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} ds \right)
     \]
     En utilisant la règle de Leibniz pour différencier une intégrale avec une borne variable :
     \[
     \dot{Y} = R \left[ \sin(x_d(t) - x_d(t)) e^{-\frac{(t - t)}{\tau}} + \int_{-\infty}^t \frac{\partial}{\partial t} \left( \sin(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} \right) ds \right]
     \]
     Le premier terme s’annule car \( \sin(0) = 0 \). Pour le second, calculons la dérivée partielle :
     \[
     \frac{\partial}{\partial t} \left( \sin(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} \right) = \cos(x_d(t) - x_d(s)) \cdot \dot{x}_d(t) e^{-\frac{(t - s)}{\tau}} - \frac{1}{\tau} \sin(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}}
     \]
     Puisque \( \dot{x}_d(t) = X \), cela devient :
     \[
     \dot{Y} = R \int_{-\infty}^t \left[ X \cos(x_d(t) - x_d(s)) - \frac{1}{\tau} \sin(x_d(t) - x_d(s)) \right] e^{-\frac{(t - s)}{\tau}} ds
     \]
     En utilisant les définitions de \( Y \) et \( Z \) :
     \[
     \dot{Y} = X Z - \frac{1}{\tau} Y
     \]
     C’est la deuxième équation.

   - De même, pour \( Z \) :
     \[
     \dot{Z} = \frac{d}{dt} \left( R \int_{-\infty}^t \cos(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} ds \right)
     \]
     Appliquons encore la règle de Leibniz :
     \[
     \dot{Z} = R \left[ \cos(x_d(t) - x_d(t)) e^{0} + \int_{-\infty}^t \frac{\partial}{\partial t} \left( \cos(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} \right) ds \right]
     \]
     Le premier terme donne \( R \cdot \cos(0) \cdot 1 = R \). Pour l’intégrale :
     \[
     \frac{\partial}{\partial t} \left( \cos(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} \right) = -\sin(x_d(t) - x_d(s)) \cdot X e^{-\frac{(t - s)}{\tau}} - \frac{1}{\tau} \cos(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}}
     \]
     Ainsi :
     \[
     \dot{Z} = R - X Y - \frac{1}{\tau} Z
     \]
     C’est la troisième équation.

4. *Système final* :
   On obtient donc le système de Lorenz :
   \[
   \begin{cases}
   \dot{X} = Y - X \\
   \dot{Y} = -\frac{1}{\tau} Y + X Z \\
   \dot{Z} = R - \frac{1}{\tau} Z - X Y
   \end{cases}
   \]

---

### Comment revenir à la solution initiale ?

Pour "revenir" à la solution initiale, c’est-à-dire reconstruire \( x_d(t) \) à partir des solutions \( X(t), Y(t), Z(t) \) du système de Lorenz, il faut intégrer \( X(t) \), car \( X = \dot{x}_d \). Voici les étapes :

1. *Obtenir \( X(t) \) à partir du système* :
   - Résolvez numériquement le système ci-dessus (par exemple, avec RK4) pour obtenir \( X(t) \) sur un intervalle de temps \( [t_0, t_f] \), avec une condition initiale comme \( (X(0), Y(0), Z(0)) = (1, 0, 0) \).

2. *Intégrer \( X(t) \) pour \( x_d(t) \)* :
   - Puisque \( X = \dot{x}_d \), on a :
     \[
     x_d(t) = x_d(0) + \int_{t_0}^t X(s) \, ds
     \]
     - \( x_d(0) \) est la position initiale, souvent fixée à 0 pour simplifier (mais peut être ajustée).
     - L’intégrale peut être calculée numériquement, par exemple avec la méthode des trapèzes ou en utilisant les points générés par RK4 :
       \[
       x_d(t_n) = x_d(0) + \sum_{i=0}^{n-1} \frac{h}{2} (X(t_i) + X(t_{i+1}))
       \]
       où \( h \) est le pas de temps et \( t_i = t_0 + i h \).

3. *Vérification avec \( F_{\text{self}} \)* :
   - Une fois \( x_d(t) \) obtenu, vous pouvez théoriquement recalculer \( F_{\text{self}} \) en évaluant l’intégrale :
     \[
     F_{\text{self}}(t) = R \int_{-\infty}^t \sin(x_d(t) - x_d(s)) e^{-\frac{(t - s)}{\tau}} ds
     \]
     - En pratique, l’intégrale est tronquée à \( t_0 \) (supposant que les contributions avant \( t_0 \) sont négligeables après un certain temps), et \( Y(t) \) obtenu par le système devrait correspondre à cette valeur.

4. *Limites pratiques* :
   - Recalculer \( F_{\text{self}} \) directement à partir de \( x_d(t) \) est coûteux et inutile, car \( Y(t) \) représente déjà cette force dans le système de Lorenz. Le passage au système d’EDO élimine le besoin de gérer explicitement l’intégrale dans la résolution.

---

### Conclusion

En posant \( Y = F_{\text{self}} \) et en introduisant \( Z \), on transforme l’équation intégro-différentielle en un système d’EDO plus simple à résoudre numériquement. Pour revenir à \( x_d(t) \), il suffit d’intégrer \( X(t) \) obtenu du système de Lorenz. Cela vous donne la trajectoire spatiale de la particule, qui est cohérente avec l’équation initiale, bien que \( Y \) et \( Z \) encapsulent déjà toute l’information dynamique nécessaire sans avoir à recalculer l’intégrale explicitement.