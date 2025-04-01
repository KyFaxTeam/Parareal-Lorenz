! filepath: derivatives.f90
module derivatives
    implicit none
    private
    public :: compute_derivatives

contains

    !> Computes the time derivatives for the Lorenz-like system (F=0).
    !>
    !> X_dot = Y - X
    !> Y_dot = -(1/tau)*Y + X*Z
    !> Z_dot = R - (1/tau)*Z - X*Y
    !>
    !> Args:
    !>   u(3)     : Current state vector [X, Y, Z]
    !>   R        : Amplitude parameter
    !>   tau      : Memory parameter
    !>   du_dt(3) : Output vector for derivatives [X_dot, Y_dot, Z_dot]
    subroutine compute_derivatives(u, R, tau, du_dt)
        real, dimension(3), intent(in) :: u
        real, intent(in) :: R, tau
        real, dimension(3), intent(out) :: du_dt
        real :: inv_tau

        ! Pre-calculate 1/tau for efficiency, handle tau=0 case
        if (abs(tau) < 1.0E-10) then
            ! Avoid division by zero, though the solver module also has checks
            inv_tau = 1.0 / 0.01 ! Use the same safe default as in rk4_solver
        else
            inv_tau = 1.0 / tau
        end if

        ! Unpack state vector for clarity
        real :: x_val, y_val, z_val
        x_val = u(1)
        y_val = u(2)
        z_val = u(3)

        ! Compute derivatives based on the equations
        du_dt(1) = y_val - x_val                   ! X_dot
        du_dt(2) = -inv_tau * y_val + x_val * z_val ! Y_dot
        du_dt(3) = R - inv_tau * z_val - x_val * y_val ! Z_dot

    end subroutine compute_derivatives

end module derivatives