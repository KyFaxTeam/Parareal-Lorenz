! filepath: /home/yanel/PA/Lorenz-RK4/domain_decomposition.f90
module domain_decomposition
    implicit none
    
    private
    public :: decompose_domain
    
contains

    subroutine decompose_domain(t0, tf, N, T_n)
        ! Divise l'intervalle temporel [t0, tf] en N sous-intervalles
        !
        ! Arguments:
        !   t0    : Temps initial
        !   tf    : Temps final
        !   N     : Nombre de sous-intervalles (processus)
        !   T_n   : Points de découpage temporel (dimension N+1)
        
        real, intent(in) :: t0, tf
        integer, intent(in) :: N
        real, dimension(0:N), intent(out) :: T_n
        
        integer :: i  ! Changed from 'n' to 'i' to avoid conflict
        real :: Delta_T
        
        ! Calcul de la taille d'un sous-intervalle
        Delta_T = (tf - t0) / N
        
        ! Distribution des points de découpage
        do i = 0, N  ! Changed from 'n' to 'i'
            T_n(i) = t0 + i * Delta_T
        end do
        
    end subroutine decompose_domain

end module domain_decomposition