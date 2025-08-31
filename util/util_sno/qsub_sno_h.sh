#!/bin/bash 
#PBS -q SMP
#PBS -l select=1:ncpus=1:mpiprocs=1
#PBS -N scale-sdm

cd ${PBS_O_WORKDIR}

module load intel/2022.3.1 mpt hdf5/1.14.3 netcdf-c/4.9.2 netcdf-fortran/4.6.1

#mpiexec_mpt dplace -s1 ./sno sno.vgridope.conf || exit 1

mpiexec_mpt dplace -s1 ./sno sno.hgridope.conf || exit 1
