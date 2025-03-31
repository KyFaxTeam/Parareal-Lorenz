# Makefile pour le projet Lorenz-RK4 avec support Parareal et MPI

# Compilateurs et flags
FC = mpif90
FFLAGS = -O2 -Wall

# Définir la méthode par défaut (rk4 ou parareal)
METHOD ?= rk4

# Cibles principales
all: lorenz_solver

# Lien final
lorenz_solver: main.o derivatives.o domain_decomposition.o rk4_solver.o param.o parareal_solver.o
	$(FC) $(FFLAGS) -o $@ $^

# Règles de compilation des modules
param.o: param.f90
	$(FC) $(FFLAGS) -c $<

derivatives.o: derivatives.f90
	$(FC) $(FFLAGS) -c $<

domain_decomposition.o: domain_decomposition.f90
	$(FC) $(FFLAGS) -c $<

rk4_solver.o: rk4_solver.f90 derivatives.o
	$(FC) $(FFLAGS) -c $<

parareal_solver.o: parareal_solver.f90 derivatives.o domain_decomposition.o rk4_solver.o
	$(FC) $(FFLAGS) -c $<

main.o: main.f90 rk4_solver.o parareal_solver.o param.o
	$(FC) $(FFLAGS) -c $<

# Exécution générique
run_rk4:
	./lorenz_solver rk4 5.0 0.001 100.0 1.0 0.0 0.0

run_parareal:
	mpirun -np 5 ./lorenz_solver parareal 5.0 0.005 0.0005 100.0 1.0 0.0 0.0

# Scénarios RK4
scenario1_rk4: lorenz_solver
	./lorenz_solver rk4 0.5 0.001 100.0 1.0 0.0 0.0
	@echo "Scénario Type 1 (État non-marcheur, convergence vers X=0) avec RK4 terminé"

scenario2_rk4: lorenz_solver
	./lorenz_solver rk4 2.0 0.005 100.0 1.0 0.0 0.0
	@echo "Scénario Type 2 (Marche régulière, X constant non nul) avec RK4 terminé"

scenario3_rk4: lorenz_solver
	./lorenz_solver rk4 5.0 0.001 100.0 1.0 0.0 0.0
	@echo "Scénario Type 3 (Marche chaotique, oscillations imprévisibles) avec RK4 terminé"

scenario4_rk4: lorenz_solver
	./lorenz_solver rk4 8.9 0.001 100.0 1.0 0.0 0.0
	@echo "Scénario Type 4 (Oscillations avec dérive) avec RK4 terminé"

# Tous les scénarios RK4
all_scenarios_rk4: scenario1_rk4 scenario2_rk4 scenario3_rk4 scenario4_rk4
	@echo "Tous les scénarios ont été exécutés avec RK4"

# Scénarios Parareal
scenario1_parareal: lorenz_solver
	mpirun -np 5 ./lorenz_solver parareal 0.5 0.01 0.001 100.0 1.0 0.0 0.0
	@echo "Scénario Type 1 (État non-marcheur, convergence vers X=0) avec Parareal terminé"

scenario2_parareal: lorenz_solver
	mpirun -np 5 ./lorenz_solver parareal 2.0 0.05 0.005 100.0 1.0 0.0 0.0
	@echo "Scénario Type 2 (Marche régulière, X constant non nul) avec Parareal terminé"

scenario3_parareal: lorenz_solver
	mpirun -np 5 ./lorenz_solver parareal 5.0 0.005 0.0005 100.0 1.0 0.0 0.0
	@echo "Scénario Type 3 (Marche chaotique, oscillations imprévisibles) avec Parareal terminé"

scenario4_parareal: lorenz_solver
	mpirun -np 5 ./lorenz_solver parareal 8.9 0.005 0.0005 100.0 1.0 0.0 0.0
	@echo "Scénario Type 4 (Oscillations avec dérive) avec Parareal terminé"

# Tous les scénarios Parareal
all_scenarios_parareal: scenario1_parareal scenario2_parareal scenario3_parareal scenario4_parareal
	@echo "Tous les scénarios ont été exécutés avec Parareal"

# Test avec différentes valeurs de tau (alias pour compatibilité avec l'ancien makefile)
test_rk4: all_scenarios_rk4

test_parareal: all_scenarios_parareal

# Comparaison des performances
benchmark: lorenz_solver
	@if [ ! -f "./lorenz_solver" ]; then \
		echo "ERROR: The executable ./lorenz_solver does not exist!"; \
		echo "Please run 'make' first to compile the program."; \
		exit 1; \
	fi
	@echo "============================================================="
	@echo "     COMPARAISON DES PERFORMANCES RK4 vs PARAREAL"
	@echo "============================================================="
	@echo "Problème de grande taille: tf=1000.0, h=0.001"
	@echo
	@echo ">> RK4 (séquentiel):"
	time ./lorenz_solver rk4 5.0 0.001 1000.0 1.0 0.0 0.0
	@echo 
	@echo ">> Parareal (4 processus):"
	time mpirun -np 5 ./lorenz_solver parareal 5.0 0.01 0.001 1000.0 1.0 0.0 0.0
	@echo
	@echo "Conseil: Plus le problème est grand (tf élevé, h petit), plus"
	@echo "l'avantage de Parareal devrait être visible."

# Nettoyage
clean:
	rm -f *.o *.mod lorenz_solver

# Nettoyage des benchmarks uniquement
clean_benchmark:
	rm -rf output/benchmark

# Nettoyage des fichiers de sortie uniquement (préserve le code compilé)
clean_outputs:
	rm -rf output/*

# Nettoyage complet (inclut les fichiers de données et graphiques)
distclean: clean
	rm -rf output/

# Benchmarking avancé
benchmark_dir:
	@mkdir -p output/benchmark

# Benchmark étendu avec séquence de tailles de problèmes
benchmark_extended: lorenz_solver benchmark_dir
	@if [ ! -f "./lorenz_solver" ]; then \
		echo "ERROR: The executable ./lorenz_solver does not exist!"; \
		echo "Please run 'make' first to compile the program."; \
		exit 1; \
	fi
	@echo "============================================================="
	@echo "     BENCHMARKING AVANCÉ RK4 vs PARAREAL - 10 POINTS"
	@echo "============================================================="
	@echo "Exécution de 10 tailles de problèmes différentes..."
	@echo "problem_size,tf,h,steps,rk4_time,parareal_time,speedup" > output/benchmark/benchmark_results.csv
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		tf=`echo "scale=1; 100 + ($$i-1) * 100" | bc`; \
		h=`echo "scale=6; 0.01 / (1 + ($$i-1) * 0.2)" | bc`; \
		steps=`echo "scale=0; $$tf / $$h" | bc`; \
		echo "Point $$i: tf=$$tf, h=$$h ($$steps étapes)"; \
		echo "RK4: exécution en cours..."; \
		rm -f output/benchmark/timing.txt; \
		./lorenz_solver rk4 5.0 $$h $$tf 1.0 0.0 0.0 --timing; \
		if [ -f "output/benchmark/timing.txt" ]; then \
			rk4_time=`cat output/benchmark/timing.txt`; \
			echo "RK4 temps: $$rk4_time seconds"; \
		else \
			rk4_time="N/A"; \
			echo "Erreur: fichier timing.txt non trouvé pour RK4"; \
		fi; \
		h_coarse=`echo "scale=6; $$h * 10" | bc`; \
		echo "Parareal: exécution en cours..."; \
		rm -f output/benchmark/timing.txt; \
		mpirun -np 5 ./lorenz_solver parareal 5.0 $$h_coarse $$h $$tf 1.0 0.0 0.0 --timing; \
		if [ -f "output/benchmark/timing.txt" ]; then \
			para_time=`cat output/benchmark/timing.txt`; \
			echo "Parareal temps: $$para_time seconds"; \
		else \
			para_time="N/A"; \
			echo "Erreur: fichier timing.txt non trouvé pour Parareal"; \
		fi; \
		if [ "$$rk4_time" != "N/A" ] && [ "$$para_time" != "N/A" ]; then \
			speedup=`echo "scale=6; $$rk4_time / $$para_time" | bc`; \
			echo "Speedup: $$speedup x"; \
		else \
			speedup="N/A"; \
			echo "Speedup calculation not possible"; \
		fi; \
		echo "point$$i,$$tf,$$h,$$steps,$$rk4_time,$$para_time,$$speedup" >> output/benchmark/benchmark_results.csv; \
	done
	@echo "Benchmarking terminé. Résultats sauvegardés dans output/benchmark/benchmark_results.csv"
	@echo "Utilisez 'python plotter.py benchmark' pour visualiser les résultats"

# Comparison Targets (RK4 vs Parareal) - Updated with tf=60.0 for better consistency
comparison_dir:
	@mkdir -p output/comparisons

compare_scenario1: lorenz_solver comparison_dir
	@echo "Executing RK4 and Parareal for Scenario 1 (Non-walker, tau=0.5)..."
	./lorenz_solver rk4 0.5 0.001 60.0 1.0 0.0 0.0
	mpirun -np 5 ./lorenz_solver parareal 0.5 0.01 0.001 60.0 1.0 0.0 0.0
	@echo "Running comparison visualization..."
	python plotter.py compare --tau=0.5 --output=output/comparisons/scenario1_comparison --no-display

compare_scenario2: lorenz_solver comparison_dir
	@echo "Executing RK4 and Parareal for Scenario 2 (Regular walker, tau=2.0)..."
	./lorenz_solver rk4 2.0 0.005 60.0 1.0 0.0 0.0
	mpirun -np 5 ./lorenz_solver parareal 2.0 0.05 0.005 60.0 1.0 0.0 0.0
	@echo "Running comparison visualization..."
	python plotter.py compare --tau=2.0 --output=output/comparisons/scenario2_comparison --no-display

compare_scenario3: lorenz_solver comparison_dir
	@echo "Executing RK4 and Parareal for Scenario 3 (Chaotic walker, tau=5.0)..."
	./lorenz_solver rk4 5.0 0.001 60.0 1.0 0.0 0.0
	mpirun -np 5 ./lorenz_solver parareal 5.0 0.005 0.0005 60.0 1.0 0.0 0.0
	@echo "Running comparison visualization..."
	python plotter.py compare --tau=5.0 --output=output/comparisons/scenario3_comparison

compare_scenario4: lorenz_solver comparison_dir
	@echo "Executing RK4 and Parareal for Scenario 4 (Oscillations with drift, tau=8.9)..."
	./lorenz_solver rk4 8.9 0.001 60.0 1.0 0.0 0.0
	mpirun -np 5 ./lorenz_solver parareal 8.9 0.005 0.0005 60.0 1.0 0.0 0.0
	@echo "Running comparison visualization..."
	python plotter.py compare --tau=8.9 --output=output/comparisons/scenario4_comparison

# Run all comparison scenarios
compare_all: compare_scenario1 compare_scenario2 compare_scenario3 compare_scenario4
	@echo "All comparison scenarios completed. Results are in output/comparisons/"
	@echo "Run 'python plotter.py analysis' to view comprehensive analysis."

# Test configurations for Scenario 1 (tau=0.5, stiff case)
test_config3_tau05: lorenz_solver
	@echo "Testing tau=0.5 with properly ordered step sizes..."
	mpirun -np 5 ./lorenz_solver parareal 0.5 0.05 0.001 100.0 1.0 0.0 0.0
	@echo "Test complete. Check output file with 'tau0.5_parareal' in name."

# Extra robust configuration for tau=0.5 with shorter time steps and more processes
test_robust_tau05: lorenz_solver
	@echo "Testing tau=0.5 with robust configuration..."
	mpirun -np 6 ./lorenz_solver parareal 0.5 0.00005 0.001 100.0 1.0 0.0 0.0
	@echo "Test complete. Check output file with 'tau0.5_parareal' in name."

# Test configurations for tau=0.5, most stable for challenging case
test_stable_tau05: lorenz_solver
	@echo "Testing tau=0.5 with extremely robust parameters..."
	mpirun -np 5 ./lorenz_solver parareal 0.5 0.01 0.001 100.0 1.0 0.0 0.0
	@echo "Test complete. Check output file with 'tau0.5_parareal' in name."

# Special configuration for tau=0.5 with relaxed convergence criteria
test_relaxed_tau05: lorenz_solver
	@echo "Testing tau=0.5 with relaxed convergence criteria..."
	mpirun -np 5 ./lorenz_solver parareal 0.5 0.01 0.001 100.0 1.0 0.0 0.0 --relaxed
	@echo "Test complete. Check output file with 'tau0.5_parareal' in name."

# Test configurations for Scenario 2 (tau=2.0)
test_config1_tau2: lorenz_solver
	@echo "Testing optimized config for tau=2.0 (h_coarse=tau/10=0.2)..."
	mpirun -np 5 ./lorenz_solver parareal 2.0 0.2 0.01 100.0 1.0 0.0 0.0
	@echo "Test complete. Check output file with 'tau2.0_parareal' in name."

# Test configurations for Scenario 3 (tau=5.0)
test_config1_tau5: lorenz_solver
	@echo "Testing optimized config for tau=5.0 (h_coarse=tau/10=0.5)..."
	mpirun -np 5 ./lorenz_solver parareal 5.0 0.5 0.01 100.0 1.0 0.0 0.0
	@echo "Test complete. Check output file with 'tau5.0_parareal' in name."

# Test configurations for Scenario 4 (tau=8.9)
test_config1_tau89: lorenz_solver
	@echo "Testing optimized config for tau=8.9 (h_coarse=tau/10=0.89)..."
	mpirun -np 5 ./lorenz_solver parareal 8.9 0.89 0.01 100.0 1.0 0.0 0.0
	@echo "Test complete. Check output file with 'tau8.9_parareal' in name."

# Run all optimized tests
test_all_optimized: test_config1_tau05 test_config1_tau2 test_config1_tau5 test_config1_tau89
	@echo "All optimized configuration tests completed."

# .PHONY définit les cibles qui ne sont pas des fichiers réels
.PHONY: all run_rk4 run_parareal test_rk4 test_parareal benchmark benchmark_extended \
	benchmark_dir clean clean_outputs clean_benchmark distclean \
	scenario1_rk4 scenario2_rk4 scenario3_rk4 scenario4_rk4 \
	all_scenarios_rk4 scenario1_parareal scenario2_parareal scenario3_parareal scenario4_parareal all_scenarios_parareal \
	comparison_dir compare_scenario1 compare_scenario2 compare_scenario3 compare_scenario4 compare_all \
	test_config1_tau05 test_config1_tau2 test_config1_tau5 test_config1_tau89 test_all_optimized test_robust_tau05 \
	test_stable_tau05 test_relaxed_tau05
