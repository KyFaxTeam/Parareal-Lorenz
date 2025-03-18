! filepath: /home/yanel/PA/Lorenz-RK4/main.f90
program main
    use mpi
    use rk4_solver
    use parareal_solver
    use param, only: R
    implicit none
    
    ! Variables pour les paramètres de simulation
    character(len=20) :: method
    real :: tau, h, tf, h_coarse
    real, dimension(3) :: u0
    integer :: max_iter
    real :: tol
    character(len=100) :: output_file
    
    ! Variables MPI
    integer :: ierr, rank, num_procs
    
    ! Variables pour le temps d'exécution
    real :: start_time, end_time
    logical :: save_timing = .false.
    character(len=100) :: timing_arg, arg
    integer :: i
    
    ! Vérifier si l'option --timing est présente
    do i = 1, command_argument_count()
        call get_command_argument(i, arg)
        if (trim(arg) == '--timing') then
            save_timing = .true.
        end if
    end do
    
    ! Initialiser MPI
    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, num_procs, ierr)
    
    ! Mesurer le temps de début
    start_time = MPI_Wtime()
    
    ! Traiter les arguments de ligne de commande (uniquement sur processus 0)
    if (rank == 0) then
        call process_arguments(method, tau, h, tf, u0, h_coarse)
    end if
    
    ! Diffuser les paramètres à tous les processus
    call MPI_Bcast(method, 20, MPI_CHARACTER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(tau, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(h, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(tf, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(u0, 3, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(h_coarse, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    
    ! Exécuter la méthode demandée
    if (method == 'rk4') then
        ! Méthode RK4 standard (uniquement sur processus 0)
        if (rank == 0) then
            write(output_file, '(a,f3.1,a)') 'output/rk4_tau', tau, '.dat'
            call solve_rk4(R, tau, 0.0, tf, h, u0, output_file)
            print *, "Calcul RK4 terminé."
        end if
    else if (method == 'parareal') then
        ! Parareal (tous les processus participent)
        max_iter = 20   ! Increased from 30 to 40 iterations
        
        ! Adaptive tolerance based on tau value
        if (tau < 1.0) then
            tol = 5.0E-4  ! Much stricter tolerance for small tau (was 1.0E-2)
        else
            tol = 1.0E-4  ! Standard tolerance for larger tau values (unchanged)
        end if
        
        call solve_parareal(R, tau, h_coarse, h, 0.0, tf, u0, max_iter, tol)
    else
        if (rank == 0) then
            print *, "Méthode non reconnue: ", trim(method)
            print *, "Méthodes disponibles: 'rk4', 'parareal'"
        end if
    end if
    
    ! Mesurer le temps de fin
    end_time = MPI_Wtime()
    
    ! Afficher le temps d'exécution (uniquement sur processus 0)
    if (rank == 0) then
        print *, ""
        print *, "======================================================"
        print *, "                 RÉSUMÉ D'EXÉCUTION"
        print *, "======================================================"
        print '(a,a)', " Méthode utilisée: ", trim(method)
        print '(a,f8.2)', " Temps de simulation: ", tf
        if (method == 'rk4') then
            print '(a,i0)', " Nombre d'étapes: ", int(tf / h)
        else
            print '(a,i0)', " Nombre de sous-domaines: ", num_procs
        end if
        print '(a,f15.6,a)', " Temps d'exécution: ", end_time - start_time, " secondes"
        print *, "======================================================"
        
        ! Sauvegarder le temps pour les benchmarks si demandé
        if (save_timing) then
            call system('mkdir -p output/benchmark')
            open(unit=99, file='output/benchmark/timing.txt', status='replace')
            write(99, '(f15.6)') end_time - start_time  ! Format avec 6 décimales
            close(99)
            print *, "Temps d'exécution sauvegardé dans output/benchmark/timing.txt"
        end if
    end if

    ! Finaliser MPI
    call MPI_Finalize(ierr)

contains

    subroutine process_arguments(method, tau, h, tf, u0, h_coarse)
        character(len=20), intent(out) :: method
        real, intent(out) :: tau, h, tf, h_coarse
        real, dimension(3), intent(out) :: u0
        
        integer :: num_args
        character(len=100) :: arg
        
        ! Valeurs par défaut
        method = 'rk4'    ! Méthode par défaut
        tau = 5.0         ! Paramètre de mémoire
        h = 0.01          ! Pas de temps fin
        h_coarse = 0.1    ! Pas de temps grossier (pour Parareal)
        tf = 100.0        ! Temps final
        u0 = [1.0, 0.0, 0.0]  ! Conditions initiales
        
        num_args = command_argument_count()
        
        if (num_args >= 1) then
            call get_command_argument(1, arg)
            method = trim(arg)
        end if
        
        if (num_args >= 2) then
            call get_command_argument(2, arg)
            read(arg, *) tau
        end if
        
        if (method == 'rk4' .and. num_args >= 3) then
            ! Format pour RK4: rk4 tau h tf x0 y0 z0
            call get_command_argument(3, arg)
            read(arg, *) h
            
            if (num_args >= 4) then
                call get_command_argument(4, arg)
                read(arg, *) tf
            end if
            
            if (num_args >= 7) then
                call get_command_argument(5, arg)
                read(arg, *) u0(1)
                call get_command_argument(6, arg)
                read(arg, *) u0(2)
                call get_command_argument(7, arg)
                read(arg, *) u0(3)
            end if
        else if (method == 'parareal' .and. num_args >= 4) then
            ! Format pour Parareal: parareal tau h_coarse h_fine tf x0 y0 z0
            call get_command_argument(3, arg)
            read(arg, *) h_coarse
            
            call get_command_argument(4, arg)
            read(arg, *) h
            
            if (num_args >= 5) then
                call get_command_argument(5, arg)
                read(arg, *) tf
            end if
            
            if (num_args >= 8) then
                call get_command_argument(6, arg)
                read(arg, *) u0(1)
                call get_command_argument(7, arg)
                read(arg, *) u0(2)
                call get_command_argument(8, arg)
                read(arg, *) u0(3)
            end if
        end if
        
        ! Add validation for critical parameters after reading them
        if (tau <= 0.0) then
            print *, "WARNING: Invalid tau value (", tau, "). Setting to default (5.0)."
            tau = 5.0
        end if
        
        if (h <= 0.0) then
            print *, "WARNING: Invalid step size (", h, "). Setting to default (0.01)."
            h = 0.01
        end if
        
        if (h_coarse <= 0.0) then
            print *, "WARNING: Invalid coarse step size (", h_coarse, "). Setting to default (0.1)."
            h_coarse = 0.1
        end if
        
        ! Afficher les paramètres
        print *, ""
        print *, "======================================================"
        print *, "              PARAMÈTRES DE SIMULATION"  
        print *, "======================================================"
        print '(a,a)', " Méthode: ", trim(method)
        print '(a,f8.3)', " Paramètre tau: ", tau
        print '(a,f10.6)', " Pas de temps fin: ", h
        
        if (method == 'parareal') then
            print '(a,f10.6)', " Pas de temps grossier: ", h_coarse
        end if
        
        print '(a,f10.2)', " Temps final: ", tf
        print '(a,f6.2,a,f6.2,a,f6.2)', " Conditions initiales: [", u0(1), ", ", u0(2), ", ", u0(3), "]"
        print *, "======================================================"
        print *, ""
        
        ! Créer le dossier de sortie s'il n'existe pas
        call system('mkdir -p output')
    end subroutine process_arguments

end program main