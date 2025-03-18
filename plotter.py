import os
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import re
import argparse
import sys
import matplotlib.gridspec as gridspec
from scipy.interpolate import interp1d

def read_data(file_path):
    """
    Lit les données de simulation à partir d'un fichier.
    
    Args:
        file_path (str): Chemin vers le fichier de données
    
    Returns:
        numpy.ndarray: Tableau des données [t, X, Y, Z]
    """
    # Read the file line by line and filter out non-numeric lines
    valid_lines = []
    with open(file_path, 'r') as f:
        header = f.readline()  # Skip the header line
        for line in f:
            line = line.strip()
            # Skip empty lines and lines with asterisks or other non-numeric characters
            if not line or '**' in line or not any(c.isdigit() for c in line):
                continue
            
            try:
                # Split the line and try to convert all values to float
                values = [float(val) for val in line.split()]
                if len(values) >= 4:  # Ensure we have at least t, X, Y, Z
                    valid_lines.append(values)
            except ValueError:
                # Skip lines that can't be converted to float
                continue
    
    if not valid_lines:
        raise ValueError(f"No valid data found in file: {file_path}")
    
    # Convert the filtered lines to a numpy array
    return np.array(valid_lines)

def is_parareal_file(file_path):
    """
    Détermine si un fichier est au format Parareal (points discrets)
    
    Args:
        file_path (str): Chemin vers le fichier de données
    
    Returns:
        bool: True si c'est un fichier Parareal, False sinon
    """
    return 'parareal' in os.path.basename(file_path).lower()

def extract_tau(file_path):
    """
    Extrait la valeur de tau à partir du nom de fichier
    
    Args:
        file_path (str): Chemin vers le fichier de données
    
    Returns:
        float: Valeur de tau ou None si non trouvée
    """
    filename = os.path.basename(file_path)
    match = re.search(r'tau(\d+\.\d+)', filename)
    if match:
        return float(match.group(1))
    return None

def plot_trajectory(file_path, plot_type='time', compare_with=None):
    """
    Génère différentes visualisations des données de simulation.
    
    Args:
        file_path (str): Chemin vers le fichier de données
        plot_type (str): Type de graphique ('time', 'phase', '3d')
        compare_with (str): Chemin vers un fichier à comparer (optionnel)
    """
    # Vérifier que le fichier existe
    if not os.path.exists(file_path):
        print(f"Erreur: Le fichier {file_path} n'existe pas.")
        return
    
    # Lire les données
    data = read_data(file_path)
    t = data[:, 0]
    X = data[:, 1]
    Y = data[:, 2]
    Z = data[:, 3]
    
    # Extraire les paramètres du nom de fichier
    filename = os.path.basename(file_path)
    tau = extract_tau(file_path)
    is_parareal = is_parareal_file(file_path)
    
    method = "Parareal" if is_parareal else "RK4"
    title_base = f"{method} (τ={tau})" if tau else f"{method}: {filename}"
    
    # Configuration du graphique en fonction du type
    if plot_type == 'time':
        plt.figure(figsize=(10, 6))
        
        # Tracé principal
        if is_parareal:
            plt.plot(t, X, 'o-', label=f'{method} X(t)', markersize=4)
            plt.plot(t, Y, 'o-', label=f'{method} Y(t)', markersize=4)
            plt.plot(t, Z, 'o-', label=f'{method} Z(t)', markersize=4)
        else:
            plt.plot(t, X, '-', label=f'{method} X(t)', linewidth=1.5)
            plt.plot(t, Y, '-', label=f'{method} Y(t)', linewidth=1.5)
            plt.plot(t, Z, '-', label=f'{method} Z(t)', linewidth=1.5)
        
        # Comparaison si demandée
        if compare_with and os.path.exists(compare_with):
            comp_data = read_data(compare_with)
            comp_t = comp_data[:, 0]
            comp_X = comp_data[:, 1]
            comp_Y = comp_data[:, 2]
            comp_Z = comp_data[:, 3]
            
            comp_method = "Parareal" if is_parareal_file(compare_with) else "RK4"
            
            # Utiliser des lignes en pointillé pour la comparaison
            plt.plot(comp_t, comp_X, '--', label=f'{comp_method} X(t)', alpha=0.7)
            plt.plot(comp_t, comp_Y, '--', label=f'{comp_method} Y(t)', alpha=0.7)
            plt.plot(comp_t, comp_Z, '--', label=f'{comp_method} Z(t)', alpha=0.7)
            
            title_base += " vs " + comp_method
        
        plt.xlabel('Temps (t)')
        plt.ylabel('Amplitude')
        plt.title(f"{title_base} - Trajectoires temporelles")
        plt.grid(True, alpha=0.3)
        plt.legend()
        plt.tight_layout()
        
        # Sauvegarder le graphique
        save_path = os.path.splitext(file_path)[0] + "_time.png"
        plt.savefig(save_path, dpi=300)
        plt.show()
        
    elif plot_type == 'phase':
        plt.figure(figsize=(8, 8))
        
        # Tracé principal
        if is_parareal:
            plt.plot(X, Z, 'o-', linewidth=1.0, markersize=4, alpha=0.8)
        else:
            plt.plot(X, Z, '-', linewidth=1.0, alpha=0.8)
        
        # Comparaison si demandée
        if compare_with and os.path.exists(compare_with):
            comp_data = read_data(compare_with)
            comp_X = comp_data[:, 1]
            comp_Z = comp_data[:, 3]
            
            comp_method = "Parareal" if is_parareal_file(compare_with) else "RK4"
            plt.plot(comp_X, comp_Z, '--', linewidth=1.0, alpha=0.5, color='red', 
                     label=comp_method)
            
            title_base += " vs " + comp_method
            plt.legend()
        
        plt.xlabel('X')
        plt.ylabel('Z')
        plt.title(f"{title_base} - Portrait de phase X-Z")
        plt.grid(True, alpha=0.3)
        
        # Sauvegarder le graphique
        save_path = os.path.splitext(file_path)[0] + "_phase.png"
        plt.savefig(save_path, dpi=300)
        plt.show()
        
    elif plot_type == '3d':
        fig = plt.figure(figsize=(10, 8))
        ax = fig.add_subplot(111, projection='3d')
        
        # Tracé principal
        if is_parareal:
            ax.plot(X, Y, Z, 'o-', linewidth=1.0, markersize=4, alpha=0.8)
        else:
            ax.plot(X, Y, Z, '-', linewidth=1.0, alpha=0.8, label=method)
        
        # Comparaison si demandée
        if compare_with and os.path.exists(compare_with):
            comp_data = read_data(compare_with)
            comp_X = comp_data[:, 1]
            comp_Y = comp_data[:, 2]
            comp_Z = comp_data[:, 3]
            
            comp_method = "Parareal" if is_parareal_file(compare_with) else "RK4"
            ax.plot(comp_X, comp_Y, comp_Z, '--', linewidth=1.0, alpha=0.5, 
                    color='red', label=comp_method)
            
            title_base += " vs " + comp_method
            ax.legend()
        
        ax.set_xlabel('X')
        ax.set_ylabel('Y')
        ax.set_zlabel('Z')
        ax.set_title(f"{title_base} - Attracteur 3D")
        
        # Sauvegarder le graphique
        save_path = os.path.splitext(file_path)[0] + "_3d.png"
        plt.savefig(save_path, dpi=300)
        plt.show()
    
    else:
        print(f"Type de graphique inconnu: {plot_type}")
        print("Types disponibles: 'time', 'phase', '3d'")

def compare_methods(tau_value=None):
    """
    Compare les résultats de RK4 et Parareal pour une valeur de tau donnée
    
    Args:
        tau_value (float): Valeur de tau pour laquelle faire la comparaison
    """
    output_dir = 'output'
    
    if not os.path.exists(output_dir):
        print(f"Erreur: Le dossier {output_dir} n'existe pas.")
        return
    
    # Chercher les fichiers correspondant à la valeur de tau
    tau_str = f"{tau_value:.1f}" if tau_value else None
    
    rk4_file = None
    parareal_file = None
    
    for file in os.listdir(output_dir):
        if not file.endswith('.dat'):
            continue
            
        file_path = os.path.join(output_dir, file)
        
        # Si tau est spécifié, filtrer par tau
        if tau_str and f"tau{tau_str}" not in file:
            continue
            
        if 'rk4' in file.lower():
            rk4_file = file_path
        elif 'parareal' in file.lower():
            parareal_file = file_path
    
    if not rk4_file or not parareal_file:
        print("Impossible de trouver les fichiers RK4 et Parareal correspondants.")
        if tau_str:
            print(f"Aucun fichier trouvé pour tau={tau_str}")
        return
    
    print(f"Comparaison de {os.path.basename(rk4_file)} et {os.path.basename(parareal_file)}")
    
    # Générer les graphiques de comparaison
    plot_trajectory(rk4_file, 'time', parareal_file)
    plot_trajectory(rk4_file, 'phase', parareal_file)
    plot_trajectory(rk4_file, '3d', parareal_file)

def analyze_all_outputs(compare=False):
    """
    Analyse tous les fichiers de sortie dans le dossier output/.
    Crée tous les types de graphiques pour chaque fichier.
    
    Args:
        compare (bool): Si True, compare les méthodes par valeur de tau
    """
    output_dir = 'output'
    
    if not os.path.exists(output_dir):
        print(f"Erreur: Le dossier {output_dir} n'existe pas.")
        return
    
    files = [f for f in os.listdir(output_dir) if f.endswith('.dat')]
    
    if not files:
        print(f"Aucun fichier .dat trouvé dans {output_dir}/")
        return
        
    print(f"Création des graphiques pour {len(files)} fichiers...")
    
    # Si compare est True, grouper les fichiers par tau
    if compare:
        tau_values = set()
        for file in files:
            tau = extract_tau(os.path.join(output_dir, file))
            if tau is not None:
                tau_values.add(tau)
        
        for tau in tau_values:
            print(f"\nComparaison des méthodes pour tau={tau}:")
            compare_methods(tau)
    else:
        # Sinon, traiter chaque fichier individuellement
        for file in files:
            file_path = os.path.join(output_dir, file)
            print(f"Traitement de {file}...")
            
            # Créer les trois types de graphiques
            plot_trajectory(file_path, 'time')
            plot_trajectory(file_path, 'phase')
            plot_trajectory(file_path, '3d')
    
    print("Analyse terminée. Tous les graphiques ont été générés.")

def analyze_benchmark_data(benchmark_dir='output/benchmark'):
    """
    Analyse les données de benchmark et génère des visualisations de performance
    
    Args:
        benchmark_dir (str): Chemin vers le répertoire contenant les fichiers de benchmark
    """
    results_file = os.path.join(benchmark_dir, 'benchmark_results.csv')
    
    if not os.path.exists(results_file):
        print(f"Erreur: Fichier de résultats des benchmarks non trouvé ({results_file})")
        print("Exécutez d'abord 'make benchmark_extended' pour générer les données")
        return
    
    # Lire les données du résumé des benchmarks
    import csv
    with open(results_file, 'r') as f:
        reader = csv.DictReader(f)
        data = list(reader)
    
    if not data:
        print("Aucune donnée de benchmark trouvée dans le fichier CSV")
        return
    
    # Extraire les données pour les graphiques
    problem_sizes = []
    tfs = []
    hs = []
    steps = []
    rk4_times = []
    parareal_times = []
    speedups = []
    
    for row in data:
        # Gestion des valeurs vides ou invalides
        try:
            problem_size = row['problem_size']
            tf = float(row['tf']) if row['tf'] else 0.0
            h = float(row['h']) if row['h'] else 0.0
            step = int(float(row['steps'])) if row['steps'] else 0
            rk4_time = float(row['rk4_time']) if row['rk4_time'] else 0.0
            parareal_time = float(row['parareal_time']) if row['parareal_time'] else 0.0
            
            # Calculer le speedup uniquement si les deux temps sont valides et non nuls
            if rk4_time > 0 and parareal_time > 0:
                speedup = rk4_time / parareal_time
            else:
                speedup = 0.0
                
            problem_sizes.append(problem_size)
            tfs.append(tf)
            hs.append(h)
            steps.append(step)
            rk4_times.append(rk4_time)
            parareal_times.append(parareal_time)
            speedups.append(speedup)
            
        except (ValueError, KeyError) as e:
            print(f"Avertissement: Ligne ignorée dans les données de benchmark - {e}")
            print(f"Contenu de la ligne: {row}")
            continue
    
    if not problem_sizes:
        print("Aucune donnée de benchmark valide trouvée après filtrage")
        return
    
    # Le reste de la fonction reste inchangé...
    # Graphique 1: Temps d'exécution vs. Nombre d'étapes
    plt.figure(figsize=(12, 7))
    
    plt.plot(steps, rk4_times, 'o-', label='RK4 (séquentiel)', linewidth=2, markersize=8)
    plt.plot(steps, parareal_times, 's-', label='Parareal (4 processus)', linewidth=2, markersize=8)
    
    plt.xlabel('Nombre d\'étapes de simulation')
    plt.ylabel('Temps d\'exécution (secondes)')
    plt.title('Temps d\'exécution en fonction de la taille du problème')
    plt.grid(True, alpha=0.3)
    plt.legend()
    
    # Utiliser une échelle logarithmique pour l'axe des x si la plage est grande
    if steps[-1] / steps[0] > 100:
        plt.xscale('log')
        plt.xlabel('Nombre d\'étapes de simulation (échelle log)')
    
    # Annoter quelques points clés
    for i in [0, len(steps)//2, -1]:  # Premier point, milieu, dernier point
        plt.annotate(f"{rk4_times[i]:.2f}s", 
                    (steps[i], rk4_times[i]), 
                    textcoords="offset points",
                    xytext=(0,10), 
                    ha='center')
        plt.annotate(f"{parareal_times[i]:.2f}s", 
                    (steps[i], parareal_times[i]), 
                    textcoords="offset points",
                    xytext=(0,-15), 
                    ha='center')
    
    plt.tight_layout()
    plt.savefig(os.path.join(benchmark_dir, 'execution_time_steps.png'), dpi=300)
    plt.show()
    
    # Graphique 2: Accélération vs. Nombre d'étapes
    plt.figure(figsize=(12, 7))
    
    plt.plot(steps, speedups, 'o-', color='green', linewidth=2, markersize=8)
    plt.axhline(y=4, color='r', linestyle='--', alpha=0.7, label='Accélération idéale (4 processus)')
    
    plt.xlabel('Nombre d\'étapes de simulation')
    plt.ylabel('Accélération (RK4 / Parareal)')
    plt.title('Accélération de Parareal par rapport à RK4')
    plt.grid(True, alpha=0.3)
    plt.legend()
    
    # Utiliser une échelle logarithmique pour l'axe des x si la plage est grande
    if steps[-1] / steps[0] > 100:
        plt.xscale('log')
        plt.xlabel('Nombre d\'étapes de simulation (échelle log)')
    
    # Annoter quelques points clés
    for i in [0, len(steps)//2, -1]:  # Premier point, milieu, dernier point
        plt.annotate(f"{speedups[i]:.2f}x", 
                    (steps[i], speedups[i]), 
                    textcoords="offset points",
                    xytext=(0,10), 
                    ha='center')
    
    plt.tight_layout()
    plt.savefig(os.path.join(benchmark_dir, 'speedup_steps.png'), dpi=300)
    plt.show()
    
    # Graphique 3: Efficacité vs. Nombre d'étapes
    plt.figure(figsize=(12, 7))
    
    efficiency = [s / 4 for s in speedups]  # Efficacité = Accélération / Nb processus
    
    plt.plot(steps, efficiency, 'o-', color='purple', linewidth=2, markersize=8)
    plt.axhline(y=1, color='r', linestyle='--', alpha=0.7, label='Efficacité idéale')
    plt.axhline(y=0.5, color='orange', linestyle='-.', alpha=0.7, label='Efficacité 50%')
    
    plt.xlabel('Nombre d\'étapes de simulation')
    plt.ylabel('Efficacité (Speedup / Nb processus)')
    plt.title('Efficacité de Parareal selon la taille du problème')
    plt.grid(True, alpha=0.3)
    plt.legend()
    
    # Utiliser une échelle logarithmique pour l'axe des x si la plage est grande
    if steps[-1] / steps[0] > 100:
        plt.xscale('log')
        plt.xlabel('Nombre d\'étapes de simulation (échelle log)')
    
    # Annoter quelques points clés
    for i in [0, len(steps)//2, -1]:  # Premier point, milieu, dernier point
        plt.annotate(f"{efficiency[i]:.2f}", 
                    (steps[i], efficiency[i]), 
                    textcoords="offset points",
                    xytext=(0,10), 
                    ha='center')
    
    plt.tight_layout()
    plt.savefig(os.path.join(benchmark_dir, 'efficiency_steps.png'), dpi=300)
    plt.show()
    
    # Graphique 4: RK4 vs Parareal - Tendance de croissance
    plt.figure(figsize=(12, 7))
    
    # Régression linéaire pour RK4 et logarithmique pour Parareal
    from scipy.optimize import curve_fit
    
    def linear_func(x, a, b):
        return a * x + b
    
    # Ajuster les courbes de tendance si suffisamment de données
    if len(steps) >= 4:
        steps_array = np.array(steps)
        rk4_array = np.array(rk4_times)
        parareal_array = np.array(parareal_times)
        
        # RK4 (devrait être linéaire avec le nombre d'étapes)
        popt_rk4, _ = curve_fit(linear_func, steps_array, rk4_array)
        rk4_trend = linear_func(steps_array, *popt_rk4)
        
        # Parareal (croissance plus lente, sous-linéaire)
        # Utiliser un fit polynômial de degré 2 pour simplifier
        z_parareal = np.polyfit(steps_array, parareal_array, 2)
        parareal_trend = np.polyval(z_parareal, steps_array)
        
        # Tracer les données et les tendances
        plt.scatter(steps, rk4_times, label='RK4 (données)', color='blue', s=50)
        plt.scatter(steps, parareal_times, label='Parareal (données)', color='red', s=50)
        plt.plot(steps_array, rk4_trend, '--', color='darkblue', linewidth=2, label='RK4 (tendance linéaire)')
        plt.plot(steps_array, parareal_trend, '--', color='darkred', linewidth=2, label='Parareal (tendance sous-linéaire)')
        
        plt.xlabel('Nombre d\'étapes de simulation')
        plt.ylabel('Temps d\'exécution (secondes)')
        plt.title('Tendances de croissance: RK4 vs Parareal')
        plt.grid(True, alpha=0.3)
        plt.legend()
        
        # Utiliser une échelle logarithmique pour l'axe des x si la plage est grande
        if steps[-1] / steps[0] > 100:
            plt.xscale('log')
            plt.xlabel('Nombre d\'étapes de simulation (échelle log)')
        
        plt.tight_layout()
        plt.savefig(os.path.join(benchmark_dir, 'growth_trends.png'), dpi=300)
        plt.show()
    
    print("\nAnalyse des benchmarks terminée. Les graphiques ont été sauvegardés dans:", benchmark_dir)
    print("\nRésumé des performances:")
    print(f"{'Problème':<10} {'Étapes':<10} {'h':<10} {'tf':<8} {'RK4':<8} {'Parareal':<8} {'Speedup':<8}")
    print("-" * 65)
    
    for i, size in enumerate(problem_sizes):
        print(f"{size:<10} {steps[i]:<10} {hs[i]:<10.6f} {tfs[i]:<8.1f} {rk4_times[i]:<8.2f}s {parareal_times[i]:<8.2f}s {speedups[i]:<8.2f}x")
    
    # Calculer l'efficacité moyenne
    avg_efficiency = sum(efficiency) / len(efficiency) if efficiency else 0
    print("\nEfficacité parallèle moyenne: {:.2f} (idéal = 1.0)".format(avg_efficiency))
    
    # Identifier le cas où Parareal est le plus efficace
    best_case_idx = speedups.index(max(speedups)) if speedups else -1
    if best_case_idx >= 0:
        print(f"Meilleure accélération: {speedups[best_case_idx]:.2f}x avec {steps[best_case_idx]} étapes (tf={tfs[best_case_idx]}, h={hs[best_case_idx]})")
    
    # Analyser l'évolution de l'efficacité avec la taille du problème
    if len(efficiency) >= 3:
        small_eff = efficiency[0]
        large_eff = efficiency[-1]
        
        if large_eff > small_eff:
            print("\nObservation: L'efficacité s'améliore avec la taille du problème.")
            print("→ Les problèmes plus grands bénéficient davantage de la parallélisation.")
        elif large_eff < small_eff:
            print("\nObservation: L'efficacité diminue avec la taille du problème.")
            print("→ Des facteurs comme la communication ou la convergence limitent l'accélération pour les grands problèmes.")
        else:
            print("\nObservation: L'efficacité reste stable quelle que soit la taille du problème.")
    
    # Estimer le point de rentabilité (taille du problème à partir de laquelle Parareal est avantageux)
    speedup_threshold = 1.0  # Parareal est avantageux quand speedup > 1
    beneficial_sizes = [steps[i] for i, s in enumerate(speedups) if s > speedup_threshold]
    
    if beneficial_sizes:
        min_beneficial = min(beneficial_sizes)
        print(f"\nPoint de rentabilité: ~{min_beneficial} étapes (à partir de ce point, Parareal devient avantageux)")
    else:
        print("\nParareal n'a pas montré d'avantage pour les tailles de problème testées.")

def compare_solutions(rk4_data, parareal_data, output_prefix=None, display=True):
    """
    Compare RK4 and Parareal solutions with detailed visualizations and error analysis
    
    Args:
        rk4_data: numpy array with RK4 data [t, X, Y, Z]
        parareal_data: numpy array with Parareal data [t, X, Y, Z]
        output_prefix: path prefix for saving plots
    """
    # Extract time and state variables
    rk4_t = rk4_data[:, 0]
    rk4_X = rk4_data[:, 1]
    rk4_Y = rk4_data[:, 2]
    rk4_Z = rk4_data[:, 3]
    
    para_t = parareal_data[:, 0]
    para_X = parareal_data[:, 1]
    para_Y = parareal_data[:, 2]
    para_Z = parareal_data[:, 3]
    
    # Create interpolation functions for Parareal data to match RK4 timestamps
    if len(para_t) < len(rk4_t):
        # Only interpolate if Parareal has fewer points
        f_X = interp1d(para_t, para_X, kind='cubic', fill_value="extrapolate")
        f_Y = interp1d(para_t, para_Y, kind='cubic', fill_value="extrapolate")
        f_Z = interp1d(para_t, para_Z, kind='cubic', fill_value="extrapolate")
        
        # Evaluate at RK4 timestamps for direct comparison
        interp_para_X = f_X(rk4_t)
        interp_para_Y = f_Y(rk4_t)
        interp_para_Z = f_Z(rk4_t)
        
        # Calculate errors
        error_X = np.abs(rk4_X - interp_para_X)
        error_Y = np.abs(rk4_Y - interp_para_Y)
        error_Z = np.abs(rk4_Z - interp_para_Z)
        
        # Calculate error metrics
        max_error_X = np.max(error_X)
        max_error_Y = np.max(error_Y)
        max_error_Z = np.max(error_Z)
        
        l2_error_X = np.sqrt(np.mean(error_X**2))
        l2_error_Y = np.sqrt(np.mean(error_Y**2))
        l2_error_Z = np.sqrt(np.mean(error_Z**2))
    else:
        # If Parareal has more or equal points, use its values directly
        interp_para_X = para_X
        interp_para_Y = para_Y
        interp_para_Z = para_Z
        error_X = error_Y = error_Z = np.zeros_like(rk4_X)
        max_error_X = max_error_Y = max_error_Z = 0
        l2_error_X = l2_error_Y = l2_error_Z = 0
    
    # 1. Side-by-side time evolution plots
    fig = plt.figure(figsize=(20, 10))
    gs = gridspec.GridSpec(3, 3, width_ratios=[1, 1, 0.8])
    
    # X variable
    ax1 = plt.subplot(gs[0, 0])
    ax1.plot(rk4_t, rk4_X, '-', label='RK4', color='blue')
    ax1.plot(para_t, para_X, 'o-', label='Parareal', color='red', markersize=4, alpha=0.7)
    ax1.set_title('X Variable Time Evolution')
    ax1.set_xlabel('Time (t)')
    ax1.set_ylabel('X')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Y variable
    ax2 = plt.subplot(gs[1, 0])
    ax2.plot(rk4_t, rk4_Y, '-', label='RK4', color='blue')
    ax2.plot(para_t, para_Y, 'o-', label='Parareal', color='red', markersize=4, alpha=0.7)
    ax2.set_title('Y Variable Time Evolution')
    ax2.set_xlabel('Time (t)')
    ax2.set_ylabel('Y')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Z variable
    ax3 = plt.subplot(gs[2, 0])
    ax3.plot(rk4_t, rk4_Z, '-', label='RK4', color='blue')
    ax3.plot(para_t, para_Z, 'o-', label='Parareal', color='red', markersize=4, alpha=0.7)
    ax3.set_title('Z Variable Time Evolution')
    ax3.set_xlabel('Time (t)')
    ax3.set_ylabel('Z')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # 2. Error plots
    if len(para_t) < len(rk4_t):
        ax4 = plt.subplot(gs[0, 1])
        ax4.plot(rk4_t, error_X, '-', color='purple')
        ax4.set_title(f'X Error (Max: {max_error_X:.4e}, L2: {l2_error_X:.4e})')
        ax4.set_xlabel('Time (t)')
        ax4.set_ylabel('|X_RK4 - X_Parareal|')
        ax4.grid(True, alpha=0.3)
        
        ax5 = plt.subplot(gs[1, 1])
        ax5.plot(rk4_t, error_Y, '-', color='purple')
        ax5.set_title(f'Y Error (Max: {max_error_Y:.4e}, L2: {l2_error_Y:.4e})')
        ax5.set_xlabel('Time (t)')
        ax5.set_ylabel('|Y_RK4 - Y_Parareal|')
        ax5.grid(True, alpha=0.3)
        
        ax6 = plt.subplot(gs[2, 1])
        ax6.plot(rk4_t, error_Z, '-', color='purple')
        ax6.set_title(f'Z Error (Max: {max_error_Z:.4e}, L2: {l2_error_Z:.4e})')
        ax6.set_xlabel('Time (t)')
        ax6.set_ylabel('|Z_RK4 - Z_Parareal|')
        ax6.grid(True, alpha=0.3)
    else:
        # If no interpolation was done, show message
        for i, ax_idx in enumerate([gs[0, 1], gs[1, 1], gs[2, 1]]):
            ax = plt.subplot(ax_idx)
            ax.text(0.5, 0.5, "Cannot calculate error:\nParallel has sparse points",
                    ha='center', va='center', fontsize=12)
            ax.set_title(f"Error Analysis for {'XYZ'[i]}")
            ax.axis('off')
    
    # 3. Trajectory comparison
    ax7 = plt.subplot(gs[:, 2], projection='3d')
    ax7.plot(rk4_X, rk4_Y, rk4_Z, '-', label='RK4', color='blue', linewidth=1.0, alpha=0.8)
    ax7.plot(para_X, para_Y, para_Z, 'o-', label='Parareal', color='red', linewidth=1.0, 
             markersize=4, alpha=0.8)
    ax7.set_title('3D Trajectory Comparison')
    ax7.set_xlabel('X')
    ax7.set_ylabel('Y')
    ax7.set_zlabel('Z')
    ax7.legend()
    
    plt.tight_layout()
    
    # Save figure if output path is provided
    if output_prefix:
        plt.savefig(f"{output_prefix}_comparison.png", dpi=300)
    
    # Only show if display is enabled
    if display:
        plt.show()
    else:
        plt.close()
    
    # 4. Phase portrait comparison (separate figure)
    plt.figure(figsize=(12, 10))
    
    # X-Z phase plot
    ax1 = plt.subplot(2, 2, 1)
    ax1.plot(rk4_X, rk4_Z, '-', label='RK4', color='blue', linewidth=1.0, alpha=0.8)
    ax1.plot(para_X, para_Z, 'o-', label='Parareal', color='red', linewidth=1.0, 
             markersize=4, alpha=0.7)
    ax1.set_title('X-Z Phase Portrait')
    ax1.set_xlabel('X')
    ax1.set_ylabel('Z')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # X-Y phase plot
    ax2 = plt.subplot(2, 2, 2)
    ax2.plot(rk4_X, rk4_Y, '-', label='RK4', color='blue', linewidth=1.0, alpha=0.8)
    ax2.plot(para_X, para_Y, 'o-', label='Parareal', color='red', linewidth=1.0, 
             markersize=4, alpha=0.7)
    ax2.set_title('X-Y Phase Portrait')
    ax2.set_xlabel('X')
    ax2.set_ylabel('Y')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Y-Z phase plot
    ax3 = plt.subplot(2, 2, 3)
    ax3.plot(rk4_Y, rk4_Z, '-', label='RK4', color='blue', linewidth=1.0, alpha=0.8)
    ax3.plot(para_Y, para_Z, 'o-', label='Parareal', color='red', linewidth=1.0, 
             markersize=4, alpha=0.7)
    ax3.set_title('Y-Z Phase Portrait')
    ax3.set_xlabel('Y')
    ax3.set_ylabel('Z')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Summary stats
    ax4 = plt.subplot(2, 2, 4)
    ax4.axis('off')
    
    # Display summary statistics
    if len(para_t) < len(rk4_t):
        summary_text = (
            "Error Analysis Summary:\n\n"
            f"X Variable:\n"
            f"  - Maximum Error: {max_error_X:.6e}\n"
            f"  - L2 Norm Error: {l2_error_X:.6e}\n\n"
            f"Y Variable:\n"
            f"  - Maximum Error: {max_error_Y:.6e}\n"
            f"  - L2 Norm Error: {l2_error_Y:.6e}\n\n"
            f"Z Variable:\n"
            f"  - Maximum Error: {max_error_Z:.6e}\n"
            f"  - L2 Norm Error: {l2_error_Z:.6e}\n"
        )
    else:
        summary_text = (
            "Error Analysis Summary:\n\n"
            "Cannot calculate detailed error metrics.\n"
            "Parareal solution has too few points\n"
            "for accurate interpolation."
        )
    
    ax4.text(0.05, 0.95, summary_text, va='top', ha='left', fontsize=12)
    
    plt.tight_layout()
    
    # Save figure if output path is provided
    if output_prefix:
        plt.savefig(f"{output_prefix}_phase_portraits.png", dpi=300)
    
    # Only show if display is enabled
    if display:
        plt.show()
    else:
        plt.close()
    
    return {
        'max_error': [max_error_X, max_error_Y, max_error_Z],
        'l2_error': [l2_error_X, l2_error_Y, l2_error_Z]
    }

def run_comparison_for_tau(tau_value, output_prefix=None, display=True):
    """
    Run a comparison analysis for a specific tau value
    
    Args:
        tau_value (float): Tau value to compare
        output_prefix (str, optional): Path prefix for saving output
    
    Returns:
        dict: Error metrics
    """
    output_dir = 'output'
    
    if not os.path.exists(output_dir):
        print(f"Error: Output directory {output_dir} not found.")
        return None
    
    # Format tau for filename matching
    tau_str = f"{tau_value:.1f}"
    
    # Always check if a dense output file exists for any tau value
    # (Since we now generate dense output for all tau values)
    use_dense = False
    dense_file = None
    
    # Look for dense output file for this tau value regardless of its magnitude
    for file in os.listdir(output_dir):
        if not file.endswith('.dat'):
            continue
            
        file_path = os.path.join(output_dir, file)
        
        # Check for dense Parareal output for this tau value
        if f"parareal_dense_tau{tau_str}" in file:
            dense_file = file_path
            use_dense = True
            print(f"Found dense output file: {os.path.basename(dense_file)}")
            break
    
    # Find the RK4 and Parareal files
    rk4_file = None
    parareal_file = None
    
    for file in os.listdir(output_dir):
        if not file.endswith('.dat'):
            continue
            
        file_path = os.path.join(output_dir, file)
        
        # Filter by tau
        if f"tau{tau_str}" not in file:
            continue
            
        if 'rk4' in file.lower():
            rk4_file = file_path
        elif not use_dense and 'parareal' in file.lower() and 'dense' not in file.lower():
            # Only use regular parareal file if dense is not available
            parareal_file = file_path
    
    # If dense file exists, use it for Parareal
    if use_dense and dense_file:
        parareal_file = dense_file
        
    if not rk4_file or not parareal_file:
        print(f"Error: Could not find RK4 and/or Parareal files for tau={tau_str}")
        return None
    
    print(f"Comparing RK4 and Parareal solutions for tau={tau_str}")
    print(f"RK4 file: {os.path.basename(rk4_file)}")
    print(f"Parareal file: {os.path.basename(parareal_file)}")
    print(f"Using {'dense' if use_dense else 'standard'} Parareal output")
    
    # Load the data
    rk4_data = read_data(rk4_file)
    parareal_data = read_data(parareal_file)
    
    # Run the comparison with display option
    metrics = compare_solutions(rk4_data, parareal_data, output_prefix, display)
    
    return metrics

def analyze_all_comparisons():
    """
    Run a comprehensive analysis of all available tau values and generate a summary
    """
    output_dir = 'output'
    
    if not os.path.exists(output_dir):
        print(f"Error: Output directory {output_dir} not found.")
        return
    
    # Find all unique tau values
    tau_values = set()
    for file in os.listdir(output_dir):
        if not file.endswith('.dat'):
            continue
        
        tau = extract_tau(os.path.join(output_dir, file))
        if tau is not None:
            tau_values.add(tau)
    
    if not tau_values:
        print("No tau values found in output files.")
        return
    
    # Sort tau values
    tau_values = sorted(tau_values)
    print(f"Found {len(tau_values)} tau values: {tau_values}")
    
    # First check for any dense output files for tau >= 5.0
    dense_files_found = False
    for tau in tau_values:
        if tau >= 5.0:
            for file in os.listdir(output_dir):
                if f"parareal_dense_tau{tau:.1f}" in file:
                    dense_files_found = True
                    print(f"Found dense output file for tau={tau:.1f}")
                    break
    
    if not dense_files_found and any(tau >= 5.0 for tau in tau_values):
        print("\nNote: No dense output files found for chaotic regimes (tau >= 5.0).")
        print("For better visualization and comparison, use the updated parareal_solver.f90")
        print("which generates dense output trajectories for these regimes.\n")
    
    # Create comparison directory if it doesn't exist
    comparison_dir = os.path.join(output_dir, 'comparisons')
    os.makedirs(comparison_dir, exist_ok=True)
    
    # Run comparison for each tau value
    results = {}
    for tau in tau_values:
        print(f"\nAnalyzing tau = {tau}...")
        output_prefix = os.path.join(comparison_dir, f"comparison_tau{tau:.1f}")
        metrics = run_comparison_for_tau(tau, output_prefix)
        
        if metrics:
            results[tau] = metrics
    
    # Create summary visualization
    if results:
        plt.figure(figsize=(12, 8))
        
        # X axis: tau values
        x = list(results.keys())
        
        # Plot max error for X, Y, Z
        max_error_X = [results[tau]['max_error'][0] for tau in x]
        max_error_Y = [results[tau]['max_error'][1] for tau in x]
        max_error_Z = [results[tau]['max_error'][2] for tau in x]
        
        plt.semilogy(x, max_error_X, 'o-', label='Max Error X', linewidth=2)
        plt.semilogy(x, max_error_Y, 's-', label='Max Error Y', linewidth=2)
        plt.semilogy(x, max_error_Z, '^-', label='Max Error Z', linewidth=2)
        
        plt.xlabel('Tau Value')
        plt.ylabel('Maximum Error (log scale)')
        plt.title('Maximum Error Between RK4 and Parareal vs. Tau')
        plt.grid(True, alpha=0.3)
        plt.legend()
        
        plt.tight_layout()
        plt.savefig(os.path.join(comparison_dir, 'error_vs_tau.png'), dpi=300)
        plt.show()
        
        # Create summary table
        print("\nSummary of Error Analysis:")
        print(f"{'Tau':<8} {'Max Error X':<15} {'Max Error Y':<15} {'Max Error Z':<15} {'L2 Error X':<15} {'L2 Error Y':<15} {'L2 Error Z':<15}")
        print("-" * 100)
        
        for tau in x:
            max_err_X, max_err_Y, max_err_Z = results[tau]['max_error']
            l2_err_X, l2_err_Y, l2_err_Z = results[tau]['l2_error']
            print(f"{tau:<8.1f} {max_err_X:<15.6e} {max_err_Y:<15.6e} {max_err_Z:<15.6e} {l2_err_X:<15.6e} {l2_err_Y:<15.6e} {l2_err_Z:<15.6e}")

def parse_command_line():
    """Parse command line arguments for automated execution"""
    parser = argparse.ArgumentParser(description='Lorenz System Visualization and Analysis Tool')
    
    # Add commands
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Compare command
    compare_parser = subparsers.add_parser('compare', help='Compare RK4 and Parareal for a specific tau')
    compare_parser.add_argument('--tau', type=float, required=True, help='Tau value to compare')
    compare_parser.add_argument('--output', type=str, help='Output prefix for saving plots')
    compare_parser.add_argument('--no-display', action='store_true', 
                              help='Do not display plots (save only)')
    
    # Analysis command
    analysis_parser = subparsers.add_parser('analysis', help='Run comprehensive analysis of all tau values')
    
    # Benchmark command
    benchmark_parser = subparsers.add_parser('benchmark', help='Analyze benchmark results')
    
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    # Check for command line arguments
    if len(sys.argv) > 1 and sys.argv[1] not in ['1', '2', '3', '4', '5']:
        args = parse_command_line()
        
        if args.command == 'compare':
            run_comparison_for_tau(args.tau, args.output, not args.no_display)
            exit(0)
        elif args.command == 'analysis':
            analyze_all_comparisons()
            exit(0)
        elif args.command == 'benchmark':
            analyze_benchmark_data()
            exit(0)
    
    # If no command line arguments or using menu options
    print("Script de visualisation pour le système de Lorenz adapté")
    print("Options:")
    print("1. Analyser un fichier spécifique")
    print("2. Analyser tous les fichiers de sortie")
    print("3. Comparer RK4 et Parareal pour une valeur de tau")
    print("4. Comparer RK4 et Parareal pour toutes les valeurs de tau")
    print("5. Analyser les résultats des benchmarks")
    
    choice = input("Choisissez une option (1/2/3/4/5): ")
    
    if choice == '1':
        output_dir = 'output'
        files = [f for f in os.listdir(output_dir) if f.endswith('.dat')]
        
        if not files:
            print(f"Aucun fichier .dat trouvé dans {output_dir}/")
        else:
            print("Fichiers disponibles:")
            for i, file in enumerate(files):
                print(f"{i+1}. {file}")
            
            file_index = int(input(f"Choisissez un fichier (1-{len(files)}): ")) - 1
            file_path = os.path.join(output_dir, files[file_index])
            
            print("Types de graphiques:")
            print("1. Trajectoires temporelles")
            print("2. Portrait de phase X-Z")
            print("3. Attracteur 3D")
            print("4. Tous les types")
            
            graph_type = input("Choisissez un type de graphique (1-4): ")
            
            if graph_type == '1':
                plot_trajectory(file_path, 'time')
            elif graph_type == '2':
                plot_trajectory(file_path, 'phase')
            elif graph_type == '3':
                plot_trajectory(file_path, '3d')
            elif graph_type == '4':
                plot_trajectory(file_path, 'time')
                plot_trajectory(file_path, 'phase')
                plot_trajectory(file_path, '3d')
    
    elif choice == '2':
        analyze_all_outputs()
    
    elif choice == '3':
        tau_values = []
        output_dir = 'output'
        
        for file in os.listdir(output_dir):
            if not file.endswith('.dat'):
                continue
                
            tau = extract_tau(os.path.join(output_dir, file))
            if tau is not None and tau not in tau_values:
                tau_values.append(tau)
        
        if not tau_values:
            print("Aucune valeur de tau trouvée dans les fichiers.")
        else:
            print("Valeurs de tau disponibles:")
            for i, tau in enumerate(tau_values):
                print(f"{i+1}. {tau}")
            
            tau_index = int(input(f"Choisissez une valeur de tau (1-{len(tau_values)}): ")) - 1
            compare_methods(tau_values[tau_index])
    
    elif choice == '4':
        analyze_all_outputs(compare=True)
    
    elif choice == '5':
        # Special handling for advanced parameter analysis
        print("\nAnalyse avancée des paramètres:")
        print("1. Effet du pas de temps grossier (h_coarse)")
        print("2. Effet du nombre de processus")
        print("3. Effet de la tolérance de convergence")
        print("4. Retour au menu principal")
        
        sub_choice = input("Choisissez une option (1/2/3/4): ")
        
        if sub_choice == '1':
            # Analyze effect of coarse step size
            print("Analyse de l'effet du pas de temps grossier...")
            # Implementation would go here
        elif sub_choice == '2':
            # Analyze effect of process count
            print("Analyse de l'effet du nombre de processus...")
            # Implementation would go here
        elif sub_choice == '3':
            # Analyze effect of tolerance
            print("Analyse de l'effet de la tolérance de convergence...")
            # Implementation would go here
    
    else:
        print("Option non valide.")
