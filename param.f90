module param
    implicit none
    
    ! Paramètres globaux
    real, parameter :: R = 2.5  ! Amplitude adimensionnée des ondes générées (valeur corrigée)
    
    ! Types de scénarios
    type scenario_type
        real :: tau      ! Paramètre de mémoire
        real :: h        ! Pas de temps
        real :: tf       ! Temps final
        real :: X0       ! Condition initiale X
        real :: Y0       ! Condition initiale Y
        real :: Z0       ! Condition initiale Z
        character(len=50) :: description  ! Description du scénario
    end type scenario_type
    
contains

    function get_scenario(scenario_id) result(scen)
        integer, intent(in) :: scenario_id
        type(scenario_type) :: scen
        
        ! Définir des valeurs par défaut
        scen%h = 0.01    ! Pas de temps par défaut
        scen%tf = 10.0  ! Temps final par défaut
        scen%X0 = 1.0    ! X initial par défaut
        scen%Y0 = 0.0    ! Y initial par défaut
        scen%Z0 = 0.0    ! Z initial par défaut
        
        ! Sélectionner le scénario en fonction de l'ID
        select case (scenario_id)
            case (1)
                scen%tau = 0.5
                scen%description = "Type 1 (État non-marcheur, convergence vers X=0)"
            case (2)
                scen%tau = 2.0
                scen%description = "Type 2 (Marche régulière, X constant non nul)"
            case (3) 
                scen%tau = 5.0
                scen%description = "Type 3 (Marche chaotique, oscillations imprévisibles)"
            case (4)
                scen%tau = 8.9
                scen%description = "Type 4 (Oscillations avec dérive)"
            case default
                ! Scénario par défaut si l'ID est invalide
                scen%tau = 2.0
                scen%description = "Scénario par défaut"
        end select
    end function get_scenario
    
end module param
