! filepath: main_lorenz_scan.f90
program main_lorenz_scan
    use simulation_parameters ! Contains physical, numerical, and scan parameters
    use rk4_solver      ! Contains solve_rk4_and_average_x
    use derivatives     ! Contains compute_derivatives (needed by solver)
    implicit none

    ! --------------------------------------------------------------------------
    ! Step 1: Parameters are now imported from simulation_parameters module
    ! --------------------------------------------------------------------------

    ! Derived parameters and variables
    real :: dr
    real :: dx0
    integer :: i_r, i_ic, n_valid_ic
    real :: current_r
    real, dimension(3) :: u0, final_u
    real, dimension(N_IC) :: avg_x_results ! Stores <X>_j for a given R
    real :: avg_x_ensemble  ! <X>_R
    real :: std_dev_ensemble ! sigma_X(R)
    real :: sum_x_ens, sum_x_sq_ens
    integer :: error_flag_solver, error_flag_io
    integer :: output_unit

    character(len=100) :: output_filename = "lorenz_scan_results.csv"
    character(len=20) :: fmt_header_part, fmt_data_num
    character(len=500) :: header_string, data_format_string

    ! --------------------------------------------------------------------------
    ! Step 5 (part 1): Setup Output File
    ! --------------------------------------------------------------------------
    open(newunit=output_unit, file=trim(output_filename), status='replace', action='write', iostat=error_flag_io)
    if (error_flag_io /= 0) then
        print *, "Error opening output file: ", trim(output_filename)
        stop "File Open Error"
    end if

    ! Construct the header string dynamically
    header_string = "R,Avg_X_Ensemble,StdDev_X_Ensemble"
    do i_ic = 1, N_IC
        write(fmt_header_part, '(A,I0)') ",Avg_X_", i_ic ! Format like ",Avg_X_1"
        header_string = trim(header_string) // trim(fmt_header_part)
    end do
    write(output_unit, '(A)') trim(header_string)

    ! Construct the data format string dynamically (e.g., '(F8.4, 2(ES14.6E2), 50(ES14.6E2))')
    ! Using ES format for scientific notation which is generally safer for varying magnitudes
    write(fmt_data_num, '(I0)') N_IC ! Get number of avg_x columns
    data_format_string = "(F8.4, 2(ES14.6E2)," // trim(fmt_data_num) // "(ES14.6E2))"

    ! --------------------------------------------------------------------------
    ! Step 6: Programme Principal (Loops)
    ! --------------------------------------------------------------------------
    print *, "========================================="
    print *, " Starting Lorenz System Scan (F=0)     "
    print *, "========================================="
    print *, "Parameters:"
    print *, "  tau =", TAU, ", dt =", DT, ", T_sim =", T_SIMULATION, ", T_trans =", T_TRANSIENT
    print *, "  N_IC =", N_IC, ", X0 range = [", X0_MIN, ",", X0_MAX, "]"
    print *, "  N_R =", N_R, ", R range = [", R_MIN, ",", R_MAX, "]"
    print *, "Output file:", trim(output_filename)
    print *, "-----------------------------------------"

    ! Calculate increments
    if (N_R > 1) then
        dr = (R_MAX - R_MIN) / real(N_R - 1)
    else
        dr = 0.0 ! Avoid division by zero if N_R=1
    end if
    if (N_IC > 1) then
        dx0 = (X0_MAX - X0_MIN) / real(N_IC - 1)
    else
        dx0 = 0.0 ! Avoid division by zero if N_IC=1
    end if

    ! Step 6.2: Boucle Principale (sur R)
    do i_r = 0, N_R - 1
        current_r = R_MIN + real(i_r) * dr
        if (N_R == 1) current_r = R_MIN ! Handle single R value case

        ! Initialize statistics for this R
        sum_x_ens = 0.0
        sum_x_sq_ens = 0.0
        n_valid_ic = 0
        avg_x_results = -999.99 ! Initialize with a placeholder (will be overwritten or marked HUGE)

        ! Print progress (e.g., every 10% or last step)
        if (mod(i_r, max(1, N_R / 10)) == 0 .or. i_r == N_R - 1) then
             print '(A, I0, A, I0, A, F8.4)', "Processing R step ", i_r+1, "/", N_R, ": R = ", current_r
        end if

        ! Step 6.2.95: Boucle Interne (sur CI_j)
        do i_ic = 1, N_IC
            ! Step 2: Génération des Conditions Initiales
            u0(1) = X0_MIN + real(i_ic - 1) * dx0
            if (N_IC == 1) u0(1) = X0_MIN ! Handle single IC case
            u0(2) = 0.0
            u0(3) = 0.0

            ! Step 3 & 4: Intégration Numérique et Calcul Moyenne
            call solve_rk4_and_average_x(current_r, TAU, 0.0, T_SIMULATION, T_TRANSIENT, DT, u0, &
                                         avg_x_results(i_ic), final_u, error_flag_solver)

            ! Step 5 (part 2): Collecter les résultats individuels & Handle errors
            if (error_flag_solver == 0) then
                ! Valid result, include in statistics
                sum_x_ens = sum_x_ens + avg_x_results(i_ic)
                sum_x_sq_ens = sum_x_sq_ens + avg_x_results(i_ic)**2
                n_valid_ic = n_valid_ic + 1
            else
                ! Simulation failed (instability), mark result and exclude from stats
                avg_x_results(i_ic) = huge(1.0) ! Mark as invalid using HUGE
                ! Optionally print a warning, but can be verbose
                ! print *, "  Warning: Instability detected for R=", current_r, ", IC_index=", i_ic, ", X0=", u0(1)
            end if
        end do ! End inner loop (i_ic)

        ! Step 5 (part 3): Calculer les statistiques d'ensemble
        if (n_valid_ic > 0) then
            avg_x_ensemble = sum_x_ens / real(n_valid_ic)
            if (n_valid_ic > 1) then
                ! Use safe variance calculation: Var = (SumSq - (Sum^2)/N) / (N-1)
                std_dev_ensemble = sqrt(max(0.0, (sum_x_sq_ens - (sum_x_ens**2)/real(n_valid_ic)) / real(n_valid_ic - 1)))
            else
                std_dev_ensemble = 0.0 ! Standard deviation is 0 for a single point
            end if
        else
            ! No valid simulations for this R
            avg_x_ensemble = huge(1.0)   ! Mark as invalid
            std_dev_ensemble = huge(1.0) ! Mark as invalid
            print *, "  Warning: No valid simulations completed for R=", current_r
        end if

        ! Step 5 (part 4): Sauvegarder les résultats pour ce R
        ! Write R, <X>_R, sigma_X(R), followed by all <X>_j
        write(output_unit, data_format_string, iostat=error_flag_io) current_r, avg_x_ensemble, std_dev_ensemble, avg_x_results
        if (error_flag_io /= 0) then
            print *, "Error writing results for R=", current_r, " to file."
            ! Decide whether to stop or continue
            ! stop "File Write Error"
        end if

    end do ! End outer loop (i_r)

    ! --------------------------------------------------------------------------
    ! Step 6.3: Fin
    ! --------------------------------------------------------------------------
    close(output_unit)
    print *, "-----------------------------------------"
    print *, "Scan finished successfully."
    print *, "Results saved to:", trim(output_filename)
    print *, "========================================="

end program main_lorenz_scan