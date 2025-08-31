#!/bin/bash 
#PBS -q SMP
#PBS -l select=1:ncpus=1:mpiprocs=1
#PBS -N scale-sdm

cd ${PBS_O_WORKDIR}

module load intel/19.1.3 mpt hdf5/1.12.0 netcdf/4.7.4 R/4.1.0

Rscript QHYD_XZ.R
