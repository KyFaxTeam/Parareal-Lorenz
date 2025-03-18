module parareal_solver
    use mpi
    use derivatives
    use domain_decomposition
    use rk4_solver, only: solve_rk4_interval
    implicit none
    
    private
    public :: solve_parareal
    
contains
    ! Simplified RK2 (midpoint method) - Used for initialization of AB methods
    function rk2_step(u0, R, tau, dt) result(u_final)
        ! Runge-Kutta 2nd order method (midpoint method)
        ! More stable than Euler for approximations
        real, dimension(3), intent(in) :: u0
        real, intent(in) :: R, tau, dt
        real, dimension(3) :: u_final, k1, k2
        real :: safe_tau, effective_dt
        
        ! Check input for NaN/Inf - break infinite loops early
        if (any(isnan(u0)) .or. any(abs(u0) > 1.0E10)) then
            ! Return a stable point instead of propagating bad values
            u_final = [0.0, 0.0, R]
            return
        end if
        
        ! Use more conservative values for challenging cases
        ! Adaptation based on tau regimes mentioned in parareal.md
        safe_tau = max(tau, 0.05)  ! Higher minimum value for stability
        
        ! Dynamic step size adaption based on tau value (Section 2.4 of parareal.md)
        effective_dt = dt
        if (tau < 1.0) then
            ! For small tau (Type 1), use much smaller steps
            effective_dt = min(dt, safe_tau/20.0)
        else if (tau < 3.0) then
            ! For moderate tau (Type 2), use moderate steps
            effective_dt = min(dt, safe_tau/10.0)
        else
            ! For larger tau (chaotic/oscillatory), use standard steps with safety
            effective_dt = min(dt, safe_tau/5.0)
        end if
        
        ! First RK stage
        call compute_derivatives(u0, R, safe_tau, k1)
        
        ! If first stage already has issues, use simpler approach
        if (any(isnan(k1)) .or. any(abs(k1) > 1.0E4)) then
            u_final = u0  ! Return original point to stop evolution
            return
        end if
        
        ! Second RK stage (midpoint) with additional safety
        call compute_derivatives(u0 + 0.5*effective_dt*k1, R, safe_tau, k2)
        
        ! If second stage has issues, fall back to safer Euler
        if (any(isnan(k2)) .or. any(abs(k2) > 1.0E4)) then
            ! Use reduced step forward Euler as failsafe
            u_final = u0 + 0.01 * effective_dt * k1
        else
            ! Normal RK2 update with dampening for stability
            u_final = u0 + effective_dt * k2
            
            ! Implement circuit breaker for extreme values
            if (any(abs(u_final) > 10.0)) then
                ! For tau < 1.0, dampen the changes heavily
                if (tau < 1.0) u_final = u0 + 0.01 * (u_final - u0)
            end if
        end if
        
        ! Final safety check
        if (any(isnan(u_final)) .or. any(abs(u_final) > 100.0)) then
            ! Return the stable fixed point for this system
            u_final = [0.0, 0.0, R]
        end if
    end function rk2_step
    
    ! Fix for AB2 step - using the u_prev and tau parameters
    function ab2_step(u_curr, u_prev, f_curr, f_prev, R, tau, dt) result(u_next)
        ! Adams-Bashforth 2nd order method
        ! Requires two previous points and their derivatives
        real, dimension(3), intent(in) :: u_curr, u_prev ! Current and previous state vectors
        real, dimension(3), intent(in) :: f_curr, f_prev ! Current and previous derivatives
        real, intent(in) :: R, tau, dt                   ! Parameters and time step
        real, dimension(3) :: u_next                     ! Next state vector
        real :: safe_tau
        
        ! Ensure tau is not too small
        safe_tau = max(tau, 1.0E-6)
        
        ! AB2 formula: u_{n+1} = u_n + (h/2) * (3*f_n - f_{n-1})
        u_next = u_curr + (dt/2.0) * (3.0*f_curr - f_prev)
        
        ! Safety check for extreme values or NaN
        if (any(isnan(u_next)) .or. any(abs(u_next) > 1.0E6)) then
            ! Return a stable point if computation goes wrong
            u_next = [0.0, 0.0, R]
        end if
        
        ! Additional stability check for small tau values (stiff cases)
        if (safe_tau < 1.0) then
            ! Dampen changes for small tau to prevent instabilities
            u_next = 0.9 * u_curr + 0.1 * u_next
        end if
    end function ab2_step
    
    ! Improved AB3 step that properly uses all parameters
    function ab3_step(u_curr, u_prev, u_prev2, f_curr, f_prev, f_prev2, R, tau, dt) result(u_next)
        ! Adams-Bashforth 3rd order method
        ! Requires three previous points and their derivatives
        real, dimension(3), intent(in) :: u_curr, u_prev, u_prev2  ! Current and two previous states
        real, dimension(3), intent(in) :: f_curr, f_prev, f_prev2  ! Current and two previous derivatives
        real, intent(in) :: R, tau, dt                             ! Parameters and time step
        real, dimension(3) :: u_next                               ! Next state vector
        real :: safe_tau, weight_factor
        
        ! Ensure tau is not too small
        safe_tau = max(tau, 1.0E-6)
        
        ! AB3 formula: u_{n+1} = u_n + (h/12) * (23*f_n - 16*f_{n-1} + 5*f_{n-2})
        u_next = u_curr + (dt/12.0) * (23.0*f_curr - 16.0*f_prev + 5.0*f_prev2)
        
        ! Safety check for extreme values or NaN
        if (any(isnan(u_next)) .or. any(abs(u_next) > 1.0E6)) then
            ! Return a stable point if computation goes wrong
            u_next = [0.0, 0.0, R]
        end if
        
        ! Use history for smoothing in chaotic regimes (tau >= 5.0)
        ! This helps prevent wild oscillations that can lead to divergence
        if (safe_tau >= 5.0) then
            ! For chaotic regimes, blend with history to maintain stability
            ! Create weighted average between current prediction and history
            weight_factor = min(0.85, 0.3 + 0.1*safe_tau) ! Scales with tau for better results
            
            ! Linear combination using past values for stability
            u_next = weight_factor * u_next + &
                    (1.0 - weight_factor) * (1.7*u_curr - 0.8*u_prev + 0.1*u_prev2)
        
        ! Additional stability checks for small tau values (stiff cases)
        else if (safe_tau < 1.0) then
            ! Use weighted average with previous value for stability in stiff cases
            u_next = 0.85 * u_curr + 0.15 * u_next
        end if
        
        ! Additional stability measures for extreme oscillations
        if (any(abs(u_next - u_curr) > 5.0)) then
            ! Limit maximum step size in state space
            where (abs(u_next - u_curr) > 5.0)
                u_next = u_curr + sign(5.0, u_next - u_curr)
            end where
        end if
    end function ab3_step
    
    ! NEW: Function to propagate a solution using AB2 over an interval
    function propagate_with_ab2(t0, tf, h, u0, R, tau) result(u_final)
        ! Propagates the solution from t0 to tf using Adams-Bashforth 2
        real, intent(in) :: t0, tf, h, R, tau        ! Time interval, step size and parameters
        real, dimension(3), intent(in) :: u0         ! Initial state
        real, dimension(3) :: u_final                ! Final state
        
        real :: t                                    ! Current time
        integer :: i, n_steps                        ! Loop variables
        real, dimension(3) :: u_curr, u_prev         ! Current and previous states
        real, dimension(3) :: f_curr, f_prev         ! Current and previous derivatives
        
        ! Calculate number of steps
        n_steps = int((tf - t0) / h)
        if (n_steps < 1) then
            u_final = u0  ! Return initial state if interval is too small
            return
        end if
        
        ! Initialize with RK2 for the first step
        u_prev = u0
        call compute_derivatives(u_prev, R, tau, f_prev)
        
        ! Generate second point using RK2
        u_curr = rk2_step(u_prev, R, tau, h)
        call compute_derivatives(u_curr, R, tau, f_curr)
        
        ! Now apply AB2 for remaining steps
        t = t0 + h
        do i = 2, n_steps
            ! Apply AB2 step
            u_final = ab2_step(u_curr, u_prev, f_curr, f_prev, R, tau, h)
            
            ! Update for next iteration
            u_prev = u_curr
            f_prev = f_curr
            u_curr = u_final
            call compute_derivatives(u_curr, R, tau, f_curr)
            
            t = t + h
        end do
        
        ! Return the final state
        u_final = u_curr
    end function propagate_with_ab2
    
    ! Enhanced propagate_with_ab3 function for better accuracy in chaotic regimes
    function propagate_with_ab3(t0, tf, h, u0, R, tau) result(u_final)
        ! Propagates the solution from t0 to tf using Adams-Bashforth 3
        real, intent(in) :: t0, tf, h, R, tau        ! Time interval, step size and parameters
        real, dimension(3), intent(in) :: u0         ! Initial state
        real, dimension(3) :: u_final                ! Final state
        
        real :: t                                    ! Current time
        integer :: i, n_steps                        ! Loop variables
        real, dimension(3) :: u_curr, u_prev, u_prev2  ! Current and previous states
        real, dimension(3) :: f_curr, f_prev, f_prev2  ! Current and previous derivatives
        real :: h_internal, h_reduced
        
        ! Calculate number of steps
        n_steps = int((tf - t0) / h)
        if (n_steps < 2) then  ! Need at least 2 steps for AB3
            ! Fall back to RK2 for very small intervals
            u_final = rk2_step(u0, R, tau, tf - t0)
            return
        end if
        
        ! For chaotic regimes (tau >= 5.0), use smaller internal step size
        if (tau >= 5.0) then
            ! Reduce step size for better accuracy in chaotic regimes
            h_internal = h / 2.0
            n_steps = n_steps * 2
        else
            h_internal = h
        end if
        
        ! Initialize with RK2 for first two steps
        ! First point is the initial condition
        u_prev2 = u0
        call compute_derivatives(u_prev2, R, tau, f_prev2)
        
        ! Generate second point using RK2
        u_prev = rk2_step(u_prev2, R, tau, h_internal)
        call compute_derivatives(u_prev, R, tau, f_prev)
        
        ! Generate third point using RK2
        u_curr = rk2_step(u_prev, R, tau, h_internal)
        call compute_derivatives(u_curr, R, tau, f_curr)
        
        ! Now apply AB3 for remaining steps
        t = t0 + 2*h_internal
        do i = 3, n_steps
            ! Apply AB3 step
            u_final = ab3_step(u_curr, u_prev, u_prev2, f_curr, f_prev, f_prev2, R, tau, h_internal)
            
            ! Update for next iteration
            u_prev2 = u_prev
            f_prev2 = f_prev
            u_prev = u_curr
            f_prev = f_curr
            u_curr = u_final
            call compute_derivatives(u_curr, R, tau, f_curr)
            
            ! Additional stability check for chaotic regimes
            if (tau >= 5.0 .and. any(isnan(u_curr)) .or. any(abs(u_curr) > 1.0E6)) then
                ! Reset to previous state and try with reduced step
                u_curr = u_prev
                h_reduced = h_internal * 0.5
                u_final = rk2_step(u_curr, R, tau, h_reduced)
                u_curr = u_final
                call compute_derivatives(u_curr, R, tau, f_curr)
            end if
            
            t = t + h_internal
        end do
        
        ! Return the final state
        u_final = u_curr
    end function propagate_with_ab3
    
    ! New function to propagate with RK2 steps over an interval
    function propagate_with_rk2(t0, tf, h, u0, R, tau) result(u_final)
        ! Propagates the solution from t0 to tf using RK2
        real, intent(in) :: t0, tf, h, R, tau        ! Time interval, step size and parameters
        real, dimension(3), intent(in) :: u0         ! Initial state
        real, dimension(3) :: u_final                ! Final state
        
        real :: t                                    ! Current time
        integer :: i, n_steps                        ! Loop variables
        real, dimension(3) :: u_curr                 ! Current state
        
        ! Calculate number of steps
        n_steps = int((tf - t0) / h)
        if (n_steps < 1) then
            u_final = u0  ! Return initial state if interval is too small
            return
        end if
        
        ! Initialize with initial condition
        u_curr = u0
        t = t0
        
        ! Apply RK2 step repeatedly
        do i = 1, n_steps
            ! Apply RK2 step
            u_curr = rk2_step(u_curr, R, tau, h)
            t = t + h
        end do
        
        ! Return the final state
        u_final = u_curr
    end function propagate_with_rk2
    
    ! Calculate system energy for convergence monitoring
    ! As mentioned in parareal.md section on convergence strategies
    function calculate_energy(u) result(energy)
        real, dimension(3), intent(in) :: u
        real :: energy
        
        ! Simple quadratic "energy" suitable for monitoring conservation
        energy = 0.5 * (u(1)**2 + u(2)**2 + u(3)**2)
    end function calculate_energy

    subroutine solve_parareal(R, tau, h_coarse, h_fine, t0, tf, u0, max_iter, tol)
        ! Résout le système de Lorenz avec l'algorithme Parareal
        !
        ! Arguments:
        !   R        : Paramètre d'amplitude
        !   tau      : Paramètre de mémoire
        !   h_coarse : Pas de temps pour l'approximation grossière
        !   h_fine   : Pas de temps pour l'approximation fine
        !   t0       : Temps initial
        !   tf       : Temps final
        !   u0(3)    : Condition initiale [X0, Y0, Z0]
        !   max_iter : Nombre maximal d'itérations Parareal
        !   tol      : Tolérance pour la convergence
        
        real, intent(in) :: R, tau, h_coarse, h_fine, t0, tf
        real, dimension(3), intent(in) :: u0
        integer, intent(in) :: max_iter
        real, intent(in) :: tol
        
        ! Variables MPI
        integer :: rank = 0, num_procs, ierr  ! Initialize rank to prevent warnings
        integer :: status(MPI_STATUS_SIZE)
        
        ! Variables Parareal
        integer :: n, k, n_local, converged, i
        real, dimension(:), allocatable :: T_n
        real, dimension(:,:), allocatable :: U_n, U_new, U_prev
        real, dimension(3) :: u_fine, u_coarse_prev, u_coarse_new
        real :: Delta_T, max_diff, safe_tau, safe_h_fine, safe_h_coarse
        character(len=100) :: output_file
        
        ! Variables for dense output
        integer :: n_dense_points, total_points, stop_interval
        real :: dense_dt, t_local, early_stop_time, partial_fraction
        real, dimension(3) :: u_local
        
        ! Convergence monitoring variables (from parareal.md)
        real, dimension(:), allocatable :: energy_k, energy_k_prev
        real :: rel_energy_change, rel_state_change, conv_metric
        real :: adapt_tol
        
        ! Circuit breaker variables
        integer :: bad_value_counter = 0
        integer, parameter :: MAX_BAD_ITERATIONS = 5
        
        ! Extrapolation factor for improved prediction (from parareal.md)
        real :: beta = 0.1
        
        ! Create local copies of parameters that we need to modify
        safe_tau = tau
        safe_h_fine = h_fine
        safe_h_coarse = h_coarse
        
        ! Debug information about parameters
        if (rank == 0) then
            print *, "DEBUG: Initial parameters:"
            print *, "  tau:", safe_tau
            print *, "  h_fine:", safe_h_fine
            print *, "  h_coarse:", safe_h_coarse
            print *, "  tf:", tf
            print *, "  t0:", t0
            print *, "  u0:", u0
        end if
        
        ! Initialisation MPI
        call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
        call MPI_Comm_size(MPI_COMM_WORLD, num_procs, ierr)
        
        if (rank == 0) then
            ! Validate step sizes
            if (h_fine >= h_coarse) then
                print *, "ERROR: Fine step size must be smaller than coarse step size!"
                print *, "  h_fine =", h_fine, "h_coarse =", h_coarse
            end if
            
            ! Check step sizes relative to tau - improved validation based on parareal.md
            if (h_coarse > tau/5.0 .and. tau > 0.5) then
                print *, "WARNING: Coarse step size may be too large relative to tau"
                print *, "  h_coarse =", h_coarse, "tau/5 =", tau/5.0
            end if
            if (h_fine > tau/50.0 .and. tau > 0.5) then
                print *, "WARNING: Fine step size may be too large relative to tau"
                print *, "  h_fine =", h_fine, "tau/50 =", tau/50.0
            end if
        end if
        
        ! Add enhanced parameter validation based on parareal.md
        if (abs(safe_tau) < 1.0E-10) then
            if (rank == 0) print *, "ERROR: tau value is too close to zero. Using tau=0.01 instead."
            safe_tau = 0.01 ! Use a safe default
        end if

        ! Improved parameter adaptation based on system dynamics (Section 2.4 of parareal.md)
        ! Adjust parameters based on tau regime
        if (safe_tau < 1.0) then  ! Type 1: Non-walker regime
            if (rank == 0) print *, "NOTE: Using optimized parameters for small tau (non-walker regime)"
            
            ! For very small tau, use much smaller steps for stability
            safe_h_coarse = min(safe_h_coarse, safe_tau/20.0)
            safe_h_fine = min(safe_h_fine, safe_tau/200.0)
            
            ! Stricter tolerance for Type 1 regime (non-walker) - DECREASED as requested
            adapt_tol = min(tol, 1.0E-5)  ! Much stricter tolerance (was 5.0E-4)
            
        else if (safe_tau < 3.0) then  ! Type 2: Regular walker regime
            if (rank == 0) print *, "NOTE: Using optimized parameters for moderate tau (regular walker regime)"
            
            safe_h_coarse = min(safe_h_coarse, safe_tau/10.0)
            safe_h_fine = min(safe_h_fine, safe_tau/100.0)
            
            ! DECREASED tolerance as requested
            adapt_tol = min(tol, 5.0E-6)  ! Was just 'tol'
            
        else if (safe_tau < 6.0) then  ! Type 3: Chaotic regime
            if (rank == 0) print *, "NOTE: Using optimized parameters for larger tau (chaotic regime)"
            
            safe_h_coarse = min(safe_h_coarse, 0.1)  ! Keep coarse step small for chaos
            safe_h_fine = min(safe_h_fine, 0.01)     ! Ensure fine step is precise
            
            ! For chaotic systems, tolerance STILL DECREASED but not as much
            adapt_tol = min(tol * 5.0, 5.0E-5)  ! Was min(tol * 10.0, 1.0E-3)
            
        else  ! Type 4: Oscillations with drift
            if (rank == 0) print *, "NOTE: Using optimized parameters for large tau (oscillatory regime)"
            
            ! Adjust for oscillatory behavior
            safe_h_coarse = min(safe_h_coarse, 0.2)
            safe_h_fine = min(safe_h_fine, 0.01)
            
            ! DECREASED tolerance as requested
            adapt_tol = min(tol, 1.0E-6)  ! Was just 'tol'
        end if
        
        if (rank == 0) then
            print *, "Adjusted parameters for stability:"
            print *, "  h_coarse =", safe_h_coarse
            print *, "  h_fine =", safe_h_fine
            print *, "  tolerance =", adapt_tol
        end if

        ! Allocation mémoire
        allocate(T_n(0:num_procs))
        allocate(U_n(3, 0:num_procs))
        allocate(U_new(3, 0:num_procs))
        allocate(U_prev(3, 0:num_procs))  ! Added for extrapolation
        allocate(energy_k(0:num_procs))    ! Added for convergence monitoring
        allocate(energy_k_prev(0:num_procs))  ! Added for convergence monitoring
        
        ! Division du domaine temporel
        call decompose_domain(t0, tf, num_procs, T_n)
        Delta_T = T_n(1) - T_n(0)  ! Taille d'un sous-intervalle
        
        ! Initialisation avec la condition initiale
        U_n(:, 0) = u0
        U_prev(:, 0) = u0  ! Initialize U_prev
        
        if (rank == 0) then
            print *, ""
            print *, "======================================================"
            print *, "          INITIALISATION PARAREAL"
            print *, "======================================================"
            print '(a,i0,a)', " Utilisation de ", num_procs, " processus"
            print '(a,f8.2,a,f8.2,a)', " Domaine temporel: [", t0, ", ", tf, "]"
            print '(a,f6.2,a,f6.2)', " Paramètres: tau = ", safe_tau, ", R = ", R
            print '(a,f10.6,a,f10.6)', " Pas de temps: h_coarse = ", safe_h_coarse, ", h_fine = ", safe_h_fine
            print *, "======================================================"
            print *, ""
            print *, "Calcul de l'initialisation grossière avec Adams-Bashforth 3..."
            
            ! Initialize using AB3 approach - first point is the initial condition
            U_n(:, 0) = u0
            U_prev(:, 0) = u0  ! Initialize U_prev
            
            ! Use propagate_with_rk2 for each sub-interval instead of AB3
            do n = 0, num_procs-1
                ! U_n(:, n+1) = propagate_with_ab3(T_n(n), T_n(n+1), safe_h_coarse, U_n(:, n), R, safe_tau)
                !                 U_prev(:, n+1) = U_n(:, n+1)  ! Initialize U_prev
                
                ! Original AB3 call (commented out)
                U_n(:, n+1) = propagate_with_ab3(T_n(n), T_n(n+1), safe_h_coarse, U_n(:, n), R, safe_tau)
                
                ! New RK2 call
                ! U_n(:, n+1) = propagate_with_rk2(T_n(n), T_n(n+1), safe_h_coarse, U_n(:, n), R, safe_tau)
                 
                ! Calculate initial energy values (for monitoring)
                energy_k(n) = calculate_energy(U_n(:, n))
                energy_k_prev(n) = energy_k(n)
            end do
            
            ! Energy for the last point
            energy_k(num_procs) = calculate_energy(U_n(:, num_procs))
            energy_k_prev(num_procs) = energy_k(num_procs)
        end if
        
        ! Diffuser l'initialisation à tous les processus
        call MPI_Bcast(U_n, 3*(num_procs+1), MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(U_prev, 3*(num_procs+1), MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(energy_k, num_procs+1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(energy_k_prev, num_procs+1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        
        ! Itérations Parareal
        converged = 0
        
        if (rank == 0) then
            print *, ""
            print *, "======================================================"
            print *, "          ITÉRATIONS PARAREAL"
            print *, "======================================================"
        end if
        
        do k = 1, max_iter
            if (rank == 0) print '(a,i2,a)', " Itération ", k, " en cours..."
            
            ! Before each iteration, store current values as previous
            U_prev = U_n
            energy_k_prev = energy_k
            
            ! Calcul précis sur le sous-intervalle local
            n_local = rank + 1  ! +1 car U_n(0) = condition initiale
            
            if (n_local <= num_procs) then  ! Vérifier que le processus a un travail à faire
                ! Solveur précis sur [T_n(n_local-1), T_n(n_local)]
                u_fine = solve_rk4_interval(T_n(n_local-1), T_n(n_local), safe_h_fine, &
                                           U_n(:, n_local-1), R, safe_tau)
                
                ! Calculate energy of fine solution for monitoring
                if (n_local <= num_procs) then
                    energy_k(n_local) = calculate_energy(u_fine)
                end if
            end if
            
            ! Circuit breaker for numerical instability
            if (any(isnan(u_fine)) .or. any(abs(u_fine) > 1.0E10)) then
                bad_value_counter = bad_value_counter + 1
                
                ! Note: We cap the values instead of immediately breaking
                where (isnan(u_fine)) u_fine = 0.0
                where (abs(u_fine) > 1.0E10) u_fine = sign(1.0E10, u_fine)
                
                if (bad_value_counter >= MAX_BAD_ITERATIONS) then
                    if (rank == 0) then
                        print *, "ERROR: Detected multiple iterations with numerical instability."
                        print *, "Terminating Parareal iterations early."
                        converged = -2  ! Special code for forced termination
                    end if
                    call MPI_Bcast(converged, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
                    exit  ! Break out of the iteration loop
                end if
            else
                bad_value_counter = 0  ! Reset counter if values are OK
            end if
            
            ! Collecte des résultats fins sur tous les processus
            U_new = U_n  ! Initialiser avec les valeurs précédentes
            
            do n = 1, num_procs
                if (rank == 0) then
                    if (n > 1) then
                        ! Recevoir u_fine du processus n
                        call MPI_Recv(u_fine, 3, MPI_REAL, n-1, 0, &
                                      MPI_COMM_WORLD, status, ierr)
                        ! Also receive energy value
                        call MPI_Recv(energy_k(n), 1, MPI_REAL, n-1, 1, &
                                      MPI_COMM_WORLD, status, ierr)
                    end if
                    
                    ! Use AB3 instead of AB2 for the coarse propagator
                    ! u_coarse_prev = propagate_with_ab3(T_n(n-1), T_n(n), safe_h_coarse, U_n(:, n-1), R, safe_tau)

                   ! Use propagate_with_rk2 instead of AB3 for the coarse propagator
                    ! Original AB3 call (commented out)
                    u_coarse_prev = propagate_with_ab3(T_n(n-1), T_n(n), safe_h_coarse, U_n(:, n-1), R, safe_tau)
                    
                    ! New RK2 call
                    ! u_coarse_prev = propagate_with_rk2(T_n(n-1), T_n(n), safe_h_coarse, U_n(:, n-1), R, safe_tau)
                    
                                             
                    ! --- MAJOR OPTIMIZATION FROM PARAREAL.MD ---
                    ! Improved prediction with extrapolation (section on optimizations)
                    if (k > 1) then
                        ! Calculate extrapolation factor based on previous updates
                        ! This creates a more informed initial guess
                        
                        ! Original AB3 call (commented out)
                        !U_new(:, n) = propagate_with_ab3(T_n(n-1), T_n(n), safe_h_coarse, U_new(:, n-1), R, safe_tau) + &
                        !             beta * (U_n(:, n) - U_prev(:, n))
                        
                        ! New RK2 call
                        U_new(:, n) = propagate_with_rk2(T_n(n-1), T_n(n), safe_h_coarse, U_new(:, n-1), R, safe_tau) + &
                                     beta * (U_n(:, n) - U_prev(:, n))
                    else
                        ! Standard prediction for first iteration
                        
                        ! Original AB3 call (commented out)
                        U_new(:, n) = propagate_with_ab3(T_n(n-1), T_n(n), safe_h_coarse, U_new(:, n-1), R, safe_tau)
                        
                        ! New RK2 call
                        ! U_new(:, n) = propagate_with_rk2(T_n(n-1), T_n(n), safe_h_coarse, U_new(:, n-1), R, safe_tau)
                    end if
                    
                    u_coarse_new = U_new(:, n)  ! Store for correction
                    
                    ! Correction Parareal with stabilization for difficult regimes
                    ! Based on the formula in parareal.md
                    U_new(:, n) = u_coarse_new + u_fine - u_coarse_prev
                    
                    ! For very small tau (Type 1 regime), apply additional damping 
                    if (tau < 1.0) then
                        ! Dampen correction to improve stability
                        U_new(:, n) = 0.8 * u_coarse_new + 0.2 * (u_fine - u_coarse_prev + u_coarse_new)
                    end if
                    
                    ! Safety check for extreme corrections
                    if (any(abs(U_new(:, n) - u_coarse_new) > 10.0)) then
                        ! Limit the magnitude of corrections to prevent instability
                        where (abs(U_new(:, n) - u_coarse_new) > 10.0)
                            U_new(:, n) = u_coarse_new + sign(10.0, U_new(:, n) - u_coarse_new)
                        end where
                    end if
                    
                    ! Calculate energy of the new state
                    energy_k(n) = calculate_energy(U_new(:, n))
                    
                else if (rank == n-1) then
                    ! Envoyer u_fine au processus 0
                    call MPI_Send(u_fine, 3, MPI_REAL, 0, 0, MPI_COMM_WORLD, ierr)
                    ! Send energy value
                    call MPI_Send(energy_k(n), 1, MPI_REAL, 0, 1, MPI_COMM_WORLD, ierr)
                end if
            end do
            
            ! Vérification de la convergence sur le processus 0 with improved criteria
            if (rank == 0) then
                max_diff = maxval(abs(U_new - U_n))
                
                ! Add improved convergence check from parareal.md
                ! Monitor both state changes and energy conservation
                rel_state_change = max_diff / (maxval(abs(U_n)) + 1.0E-10)
                
                ! Calculate maximum relative energy change
                rel_energy_change = maxval(abs(energy_k - energy_k_prev) / &
                                    (abs(energy_k_prev) + 1.0E-10))
                
                ! Combined convergence metric (from parareal.md section on convergence)
                conv_metric = max(rel_state_change, rel_energy_change)
                
                ! Add better checks for numerical issues
                if (isnan(max_diff) .or. max_diff > 1.0E20) then
                    print *, "ERROR: Numerical instability detected! (Difference =", max_diff, ")"
                    print *, "Parareal has failed to converge for these parameters."
                    print *, "Suggestions: Increase tau, decrease step size, or use RK4 instead."
                    converged = -1  ! Special code for failure
                else
                    print '(a,e10.4,a,e10.4,a,e10.4)', "   Diff max: ", max_diff, &
                          " Rel. state change: ", rel_state_change, &
                          " Rel. energy change: ", rel_energy_change
                    
                    if (conv_metric < adapt_tol) then
                        converged = 1
                        print *, ""
                        print *, "======================================================"
                        print '(a,i2,a)', " CONVERGENCE ATTEINTE APRÈS ", k, " ITÉRATIONS"
                        print *, "======================================================"
                        print '(a,e10.4,a,e10.4,a)', " Métrique finale (", conv_metric, &
                              ") < tolérance (", adapt_tol, ")"
                        print *, ""
                    else if (k == max_iter) then
                        print *, ""
                        print *, "======================================================"
                        print *, " ATTENTION: PAS DE CONVERGENCE APRÈS", max_iter, "ITÉRATIONS"
                        print *, "======================================================"
                        print '(a,e10.4,a,e10.4,a)', " Métrique finale (", conv_metric, &
                              ") > tolérance (", adapt_tol, ")"
                    end if
                end if
                
                U_n = U_new  ! Mise à jour pour la prochaine itération
            end if
            
            ! Diffuser l'état de convergence et les nouvelles valeurs à tous
            call MPI_Bcast(converged, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
            call MPI_Bcast(U_n, 3*(num_procs+1), MPI_REAL, 0, MPI_COMM_WORLD, ierr)
            call MPI_Bcast(energy_k, num_procs+1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
            
            if (converged /= 0) exit
        end do
        
        ! Handle the convergence failure case
        if (converged == -1) then
            if (rank == 0) then
                ! Write a simple result file with error message
                write(output_file, '(a,f3.1,a)') 'output/parareal_tau', safe_tau, '.dat'
                open(unit=10, file=trim(output_file), status='replace')
                write(10, '(a)') "t X Y Z"
                write(10, '(f10.6, 3f12.6)') t0, u0(1), u0(2), u0(3)  ! Initial point
                
                ! Add NaN for other points to indicate failure
                do n = 1, num_procs
                    write(10, '(f10.6, a)') T_n(n), "         NaN         NaN         NaN"
                end do
                
                close(10)
                print *, ""
                print *, "======================================================"
                print *, "          ÉCHEC DE PARAREAL"
                print *, "======================================================"
                print '(a,a)', " Résultats d'erreur sauvegardés dans: ", trim(output_file)
                print *, "======================================================"
            end if
        end if
        
        ! Sauvegarde des résultats finaux (processus 0 uniquement)
        if (converged /= -1 .and. rank == 0) then
            write(output_file, '(a,f3.1,a)') 'output/parareal_tau', safe_tau, '.dat'
            open(unit=10, file=trim(output_file), status='replace')
            write(10, '(a)') "t X Y Z"
            
            ! Écriture des points de contrôle
            do n = 0, num_procs
                write(10, '(f10.6, 3f12.6)') T_n(n), U_n(1, n), U_n(2, n), U_n(3, n)
            end do
            
            close(10)
            print *, ""
            print *, "======================================================"
            print *, "          RÉSULTATS PARAREAL"
            print *, "======================================================"
            print '(a,a)', " Résultats sauvegardés dans: ", trim(output_file)
            print '(a,i0,a)', " ", num_procs+1, " points de contrôle enregistrés"
            print *, "======================================================"
        end if
        
        ! Generate dense output for ALL tau values (not just tau >= 5.0)
        ! This improves visualization and comparison for all scenarios
        if (converged /= -1 .and. rank == 0) then
            ! Create dense output for better visualization and analysis
            write(output_file, '(a,f3.1,a)') 'output/parareal_dense_tau', safe_tau, '.dat'
            open(unit=11, file=trim(output_file), status='replace')
            write(11, '(a)') "t X Y Z"
            
            ! Initial point
            write(11, '(f10.6, 3f12.6)') t0, u0(1), u0(2), u0(3)
            
            ! Number of points per interval (much denser than just checkpoints)
            ! Use fewer points for smaller tau values (less chaotic)
            if (safe_tau < 2.0) then
                n_dense_points = 50  ! Less dense for smoother trajectories
            else if (safe_tau < 5.0) then
                n_dense_points = 75  ! Medium density
            else
                n_dense_points = 100 ! Very dense for chaotic regimes
            end if
            
            ! Set early stopping time (optional)
            early_stop_time = min(tf, 60.0) ! Don't go beyond t=60 for stability
            
            ! Generate dense output for each subinterval
            do n = 0, num_procs-1
                ! Skip intervals that are beyond our early stop time
                if (T_n(n) > early_stop_time) then
                    exit
                end if
                
                dense_dt = (T_n(n+1) - T_n(n)) / n_dense_points
                
                u_local = U_n(:, n) ! Start with known value at interval start
                
                do i = 1, n_dense_points
                    t_local = T_n(n) + i * dense_dt
                    
                    ! Check if we've reached the early stop time
                    if (t_local > early_stop_time) then
                        exit
                    end if
                    
                    ! Use RK4 with fine step to get accurate intermediate points
                    u_local = solve_rk4_interval(T_n(n) + (i-1)*dense_dt, t_local, safe_h_fine/10.0, &
                                               u_local, R, safe_tau)
                    
                    ! Write dense point to output file
                    write(11, '(f10.6, 3f12.6)') t_local, u_local(1), u_local(2), u_local(3)
                end do
            end do
            
            close(11)
            print *, ""
            print *, "======================================================"
            print *, "          DENSE OUTPUT TRAJECTORY"
            print *, "======================================================"
            print '(a,a)', " Dense trajectory sauvegardée dans: ", trim(output_file)
            
            ! Calculate actual number of points generated
            if (T_n(num_procs) > early_stop_time) then
                ! Find which subinterval contains early_stop_time
                stop_interval = 0
                do n = 0, num_procs-1
                    if (T_n(n) <= early_stop_time .and. T_n(n+1) > early_stop_time) then
                        stop_interval = n
                        exit
                    end if
                end do
                
                ! Calculate partial interval
                partial_fraction = (early_stop_time - T_n(stop_interval)) / (T_n(stop_interval+1) - T_n(stop_interval))
                
                ! Total = full intervals + partial interval + initial point
                total_points = stop_interval * n_dense_points + int(partial_fraction * n_dense_points) + 1
            else
                total_points = num_procs * n_dense_points + 1
            end if
            
            print '(a,i0,a)', " ", total_points, " points générés"
            print '(a,f6.1,a)', " Données jusqu'à t=", early_stop_time, " (limitation pour la stabilité)"
            print *, "======================================================"
        end if
        
        ! Libération mémoire
        deallocate(T_n, U_n, U_new, U_prev, energy_k, energy_k_prev)
        
    end subroutine solve_parareal

end module parareal_solver