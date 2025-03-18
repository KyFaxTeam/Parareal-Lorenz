! filepath: /home/yanel/PA/Lorenz-RK4/derivatives.f90
module derivatives
    implicit none
    
    private
    public :: compute_derivatives
    
contains

    subroutine compute_derivatives(u, R, tau, f)
        ! Calcule les dérivées du système de Lorenz
        !
        ! Arguments:
        !   u(3)  : État actuel [X, Y, Z]
        !   R     : Paramètre d'amplitude
        !   tau   : Paramètre de mémoire
        !   f(3)  : Résultat - dérivées [dX/dt, dY/dt, dZ/dt]
        
        real, dimension(3), intent(in) :: u
        real, intent(in) :: R, tau
        real, dimension(3), intent(out) :: f
        
        ! Prevent division by zero or very small tau values
        real :: safe_tau
        
        ! Check for NaN or infinity in inputs first
        if (any(isnan(u)) .or. any(abs(u) > 1.0E30)) then
            ! Input already contains NaN or Inf - return zeros to break the loop
            f = 0.0
            return
        end if
        
        ! Ensure tau is not too small to avoid numerical instability
        safe_tau = max(tau, 1.0E-6)  ! Increased minimum value for more stability
        
        ! Le système d'équations de Lorenz avec des vérifications de sécurité
        f(1) = u(2) - u(1)                          ! dX/dt
        f(2) = -(1.0/safe_tau) * u(2) + u(1) * u(3) ! dY/dt
        f(3) = R - (1.0/safe_tau) * u(3) - u(1) * u(2) ! dZ/dt
        
        ! Prevent extremely large derivatives that lead to instability
        if (any(abs(f) > 1.0E6)) then
            ! Normalize to prevent explosion
            where (abs(f) > 1.0E6) 
                f = sign(1.0E6, f)
            end where
        end if
        
        ! Debug log for numerical instability
        if (any(abs(f) > 1.0E5) .or. any(isnan(f))) then
            print *, "WARNING: Potential instability in derivatives:"
            print *, "  State u:", u
            print *, "  Parameters: R =", R, "tau =", safe_tau
            print *, "  Derivatives f:", f
            print *, "  1/tau term:", 1.0/safe_tau
        end if
        
        ! Final check for NaN values
        if (any(isnan(f))) then
            print *, "WARNING: NaN detected in derivatives at state:", u
            ! Provide safe default values if NaN occurs
            f = 0.0  ! Stop evolution completely if NaN occurs
        end if
    end subroutine compute_derivatives

end module derivatives