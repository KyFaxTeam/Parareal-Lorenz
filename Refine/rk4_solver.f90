! filepath: /home/yanel/PA/Lorenz-RK4/rk4_solver.f90
module rk4_solver
    use derivatives
    implicit none
    
    private
    public :: solve_rk4, solve_rk4_interval, solve_rk4_and_average_x
    
contains

    subroutine solve_rk4(R, tau, t0, tf, h, u0, output_file)
        ! Résout le système de Lorenz avec la méthode RK4 et sauvegarde les résultats
        !
        ! Arguments:
        !   R           : Paramètre d'amplitude
        !   tau         : Paramètre de mémoire
        !   t0          : Temps initial
        !   tf          : Temps final
        !   h           : Pas de temps
        !   u0(3)       : Condition initiale [X0, Y0, Z0]
        !   output_file : Nom du fichier de sortie (optionnel)
        
        real, intent(in) :: R, tau, t0, tf, h
        real, dimension(3), intent(in) :: u0
        character(len=*), intent(in), optional :: output_file
        
        real :: t, safe_tau
        integer :: i, n_steps, unit_num
        real, dimension(3) :: u, k1, k2, k3, k4
        character(len=100) :: filename
        logical :: save_output
        
        ! Initialisation
        u = u0
        t = t0
        n_steps = int((tf - t0) / h)
        save_output = present(output_file)
        
        ! Create a local copy of tau that can be modified
        safe_tau = tau
        
        ! Add a validation step for parameters
        if (abs(safe_tau) < 1.0E-10) then
            print *, "ERROR: tau value is too close to zero. Using tau=0.01 instead."
            safe_tau = 0.01 ! Use a safe default
        end if
        
        if (h > 0.1) then
            print *, "WARNING: Step size h=", h, " may be too large for stability."
            print *, "Consider using a smaller step size (h<=0.01) for better results."
        end if
        
        ! Préparation de la sortie si nécessaire
        if (save_output) then
            filename = output_file
            open(newunit=unit_num, file=trim(filename), status='replace')
            write(unit_num, '(a)') "t X Y Z"
            write(unit_num, '(f10.6, 3f12.6)') t, u(1), u(2), u(3)
        end if
        
        ! Intégration RK4
        do i = 1, n_steps
            ! Calcul des coefficients k1, k2, k3, k4
            call compute_derivatives(u, R, safe_tau, k1)
            call compute_derivatives(u + 0.5*h*k1, R, safe_tau, k2)
            call compute_derivatives(u + 0.5*h*k2, R, safe_tau, k3)
            call compute_derivatives(u + h*k3, R, safe_tau, k4)
            
            ! Mise à jour de l'état
            u = u + (h/6.0) * (k1 + 2.0*k2 + 2.0*k3 + k4)
            
            ! Check for numerical instability
            if (any(isnan(u)) .or. any(abs(u) > 1.0E6)) then
                print *, "WARNING: Numerical instability detected at t =", t
                print *, "Current state:", u
                print *, "Adjusting simulation parameters might be necessary."
                print *, "Try decreasing the step size h or handling this specific case."
                
                ! Try to recover from instability by resetting to last valid state
                ! This is just a simple recovery strategy
                u = u0 ! Reset to initial condition as a simple fallback
                ! Or you could implement a more sophisticated recovery
            end if
            
            t = t + h
            
            ! Écriture des résultats si nécessaire
            if (save_output) then
                write(unit_num, '(f10.6, 3f12.6)') t, u(1), u(2), u(3)
            end if
        end do
        
        ! Fermeture du fichier de sortie
        if (save_output) then
            close(unit_num)
        end if
    end subroutine solve_rk4
    
    function solve_rk4_interval(t0, tf, h, u0, R, tau) result(u_final)
        ! Calcule l'état final après intégration sur un intervalle [t0, tf]
        ! sans sauvegarder les résultats intermédiaires
        !
        ! Arguments:
        !   t0       : Temps initial
        !   tf       : Temps final
        !   h        : Pas de temps
        !   u0(3)    : État initial [X0, Y0, Z0]
        !   R        : Paramètre d'amplitude
        !   tau      : Paramètre de mémoire
        !
        ! Retourne:
        !   u_final(3) : État final [X, Y, Z] à tf
        
        real, intent(in) :: t0, tf, h, R, tau
        real, dimension(3), intent(in) :: u0
        real, dimension(3) :: u_final
        
        real :: t, safe_tau
        integer :: i, n_steps
        real, dimension(3) :: u, k1, k2, k3, k4
        
        ! Initialisation
        u = u0
        t = t0
        n_steps = int((tf - t0) / h)
        
        ! Create a local copy of tau that can be modified
        safe_tau = tau
        
        ! Add validation for tau
        if (abs(safe_tau) < 1.0E-10) then
            safe_tau = 0.01 ! Use a safe default (no print here as this is called repeatedly)
        end if
        
        ! Intégration RK4
        do i = 1, n_steps
            call compute_derivatives(u, R, safe_tau, k1)
            call compute_derivatives(u + 0.5*h*k1, R, safe_tau, k2)
            call compute_derivatives(u + 0.5*h*k2, R, safe_tau, k3)
            call compute_derivatives(u + h*k3, R, safe_tau, k4)
            
            u = u + (h/6.0) * (k1 + 2.0*k2 + 2.0*k3 + k4)
            t = t + h
        end do
        
        u_final = u
    end function solve_rk4_interval
    
    !> Solves the system using RK4 and calculates the average of X over the post-transient interval.
    !>
    !> Args:
    !>   R           : Amplitude parameter
    !>   tau         : Memory parameter
    !>   t0          : Initial time
    !>   tf          : Final time
    !>   t_transient : Time after which to start averaging
    !>   h           : Time step
    !>   u0(3)       : Initial condition [X0, Y0, Z0]
    !>
    !> Returns:
    !>   avg_x       : Average value of X for t > t_transient
    !>   final_u(3)  : Final state [X, Y, Z] at tf (optional, useful for debugging/attractors)
    !>   error_flag  : Integer flag (0=OK, 1=Instability detected)
    subroutine solve_rk4_and_average_x(R, tau, t0, tf, t_transient, h, u0, avg_x, final_u, error_flag)
        real, intent(in) :: R, tau, t0, tf, t_transient, h
        real, dimension(3), intent(in) :: u0
        real, intent(out) :: avg_x
        real, dimension(3), intent(out) :: final_u
        integer, intent(out) :: error_flag

        real :: t, safe_tau, sum_x
        integer :: i, n_steps, n_avg_steps
        real, dimension(3) :: u, k1, k2, k3, k4
        logical :: averaging_started

        ! Initialization
        u = u0
        t = t0
        n_steps = nint((tf - t0) / h) ! Use nint for robustness
        sum_x = 0.0
        n_avg_steps = 0
        averaging_started = .false.
        error_flag = 0 ! 0 indicates no error initially

        ! Create a local copy of tau that can be modified
        safe_tau = tau
        if (abs(safe_tau) < 1.0E-10) then
            safe_tau = 0.01 ! Use a safe default
        end if

        ! RK4 Integration Loop
        do i = 1, n_steps
            ! Check if we should start averaging
            if (t >= t_transient .and. .not. averaging_started) then
                 averaging_started = .true.
                 ! Optional: Print a message when averaging starts
                 ! print *, "Starting averaging at t=", t
            end if

            ! Compute derivatives
            call compute_derivatives(u, R, safe_tau, k1)
            call compute_derivatives(u + 0.5*h*k1, R, safe_tau, k2)
            call compute_derivatives(u + 0.5*h*k2, R, safe_tau, k3)
            call compute_derivatives(u + h*k3, R, safe_tau, k4)

            ! Update state
            u = u + (h/6.0) * (k1 + 2.0*k2 + 2.0*k3 + k4)
            t = t + h ! Update time *after* using the state at the beginning of the step

            ! Accumulate X if in the averaging period
            if (averaging_started) then
                sum_x = sum_x + u(1) ! Add the X value *at the end* of the step
                n_avg_steps = n_avg_steps + 1
            end if

            ! Check for numerical instability (simplified check)
            if (any(isnan(u)) .or. any(abs(u) > 1.0E7)) then ! Increased threshold slightly
                ! print *, "WARNING: Instability detected in solve_rk4_and_average_x at t =", t - h ! Time before update
                ! print *, "State:", u
                error_flag = 1 ! Set error flag
                avg_x = huge(1.0) ! Return a large number to indicate failure
                final_u = u ! Return the unstable state
                return ! Exit subroutine immediately
            end if
        end do

        ! Calculate average X
        if (n_avg_steps > 0) then
            avg_x = sum_x / real(n_avg_steps)
        else
            avg_x = 0.0 ! Or handle as an error/warning if no steps were averaged
            ! print *, "WARNING: No steps were averaged. t_transient might be >= tf."
        end if

        final_u = u ! Return the final state

    end subroutine solve_rk4_and_average_x

end module rk4_solver