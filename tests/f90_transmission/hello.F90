!!--------------------------------------------------------------------------!
!! libNEGF: a general library for Non-Equilibrium Green's functions.        !
!! Copyright (C) 2012                                                       !
!!                                                                          !
!! This file is part of libNEGF: a library for                              !
!! Non Equilibrium Green's Function calculation                             !
!!                                                                          !
!! Developers: Alessandro Pecchia, Gabriele Penazzi                         !
!! Former Conctributors: Luca Latessa, Aldo Di Carlo                        !
!!                                                                          !
!! libNEGF is free software: you can redistribute it and/or modify          !
!! it under the terms of the GNU Lesse General Public License as published  !
!! by the Free Software Foundation, either version 3 of the License, or     !
!! (at your option) any later version.                                      !
!!                                                                          !
!!  You should have received a copy of the GNU Lesser General Public        !
!!  License along with libNEGF.  If not, see                                !
!!  <http://www.gnu.org/licenses/>.                                         !
!!--------------------------------------------------------------------------!

program hello

  use libnegf
  use lib_param
  use integrations
  use mpi_f08

  implicit none

  !Type(Tnegf), target :: negf
  Type(Tnegf) :: pnegf
  Type(lnParams) :: params
  integer, allocatable :: surfstart(:), surfend(:), contend(:), plend(:), cblk(:)
  real(kind(1.d0)), allocatable :: mu(:), kt(:), coupling(:)
  real(kind(1.d0)) :: current
  integer :: ierr
  type(MPI_Comm) :: cartComm
  type(MPI_Comm) :: kComm, enComm

  call MPI_Init(ierr);

  surfstart = [61, 81]
  surfend = [60, 80]
  contend = [80, 100]
  plend = [10, 20, 30, 40, 50, 60]
  mu = [-0.5d0, 0.5d0]
  kt = [1.0d-3, 1.0d-3]
  cblk = [6, 1]

  !pnegf => negf

  write(*,*) 'Initializing libNEGF'
  call init_negf(pnegf)

  write(*,*) 'Setup MPI communicator'
  !call set_mpi_bare_comm(pnegf, MPI_COMM_WORLD) 
  call set_cartesian_bare_comms(pnegf, MPI_COMM_WORLD, 1, cartComm, kComm, enComm)

  write(*,*) 'Import Hamiltonian'
  call read_HS(pnegf, "H_real.dat", "H_imm.dat", 0)
  call set_S_id(pnegf, 100)

  call init_contacts(pnegf, 2)
  call init_structure(pnegf, 2, surfstart, surfend, contend, 6, plend, cblk)

  ! Here we set the parameters, only the ones different from default
  call get_params(pnegf, params)
  params%verbose = 100
  params%Emin = -2.d0
  params%Emax = 2.d0
  params%Estep = 2.d-2
  params%mu(1:2) = mu
  params%kbT_t(1:2) = kt
  call set_params(pnegf, params)

  ! Check values for 0 and finite coupling.
  write(*,*) '------------------------------------------------------------------ '
  write(*,*) 'Test 1 - current from coherent transmission'
  write(*,*) '------------------------------------------------------------------ '
  write(*,*) 'Compute current'
  call compute_current(pnegf)
  ! The current should be 2: energy window is 1 and
  ! spin degeneracy is 2.
  write(*,*) 'Current ', pnegf%currents(1)
  print*,'skip test'
  !if (abs(pnegf%currents(1) - 2.0) > 1e-4) then
  !   error stop "Wrong current for zero coupling"
  !end if

  call writeMemInfo(6)
  write(*,*) 'Destroy negf'
  call destroy_negf(pnegf)
  call writePeakInfo(6)
  call writeMemInfo(6)
  write(*,*) 'Done'
  
  call MPI_finalize(ierr);

end program hello
