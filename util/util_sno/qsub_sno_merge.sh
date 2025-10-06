#!/bin/bash
#PBS -q SMP
#PBS -l select=1:ncpus=12:mpiprocs=12
#PBS -N sno-merge

cd ${PBS_O_WORKDIR}

module load intel/2022.3.1 mpt hdf5/1.14.3 netcdf-c/4.9.2 netcdf-fortran/4.6.1

mpiexec_mpt dplace -s1 ./sno sno_merge.conf || exit 1