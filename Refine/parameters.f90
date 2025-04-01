! filepath: parameters.f90
module simulation_parameters
    implicit none

    ! Description: Defines the core physical and numerical parameters for the
    !              Lorenz system scan simulation based on algorithme.md.

    public :: TAU, DT, T_SIMULATION, T_TRANSIENT, N_IC, X0_MIN, X0_MAX, R_MIN, R_MAX, N_R

    ! Physical Parameters
    real, parameter :: TAU = 10.0          ! Taux de décroissance de l'onde (Memory parameter)

    ! Numerical Parameters
    real, parameter :: DT = 0.01           ! Pas de temps (Time step)
    real, parameter :: T_SIMULATION = 5000.0 ! Durée totale de simulation (Total simulation time)
    real, parameter :: T_TRANSIENT = T_SIMULATION / 2.0 ! Durée transitoire (Transient time)

    ! Scan Parameters
    integer, parameter :: N_IC = 50        ! Nombre de conditions initiales par R (Number of initial conditions per R)
    real, parameter :: X0_MIN = -5.0       ! Intervalle pour X(0) min (Range for X(0) min)
    real, parameter :: X0_MAX = 5.0        ! Intervalle pour X(0) max (Range for X(0) max)
    real, parameter :: R_MIN = 0.5         ! Intervalle pour R min (Range for R min)
    real, parameter :: R_MAX = 3.0         ! Intervalle pour R max (Range for R max)
    integer, parameter :: N_R = 100        ! Nombre de points pour R (Number of points for R)

    ! Output Parameters (Could also be moved here if desired)
    ! character(len=100), parameter :: DEFAULT_OUTPUT_FILENAME = "lorenz_scan_results.csv"

end module simulation_parameters