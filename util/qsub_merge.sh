#!/bin/bash 
#PBS -q SMP
#PBS -l select=1:ncpus=1:mpiprocs=1
#PBS -N scale

echo "Job Started at $(date)"

source ~/miniconda3/etc/profile.d/conda.sh

CONDA_ENV_NAME="nco_env"
echo "Activating Conda environment: $CONDA_ENV_NAME"
conda activate $CONDA_ENV_NAME

cd ${PBS_O_WORKDIR}

ncrcat merged-h_history.pe000000.nc merged-h_restart_history.pe000000.nc merged-h_alltime_history.pe000000.nc

if [ $? -eq 0 ]; then
  echo "Successfully merged files."
else
  echo "Error during ncrcat execution."
fi

conda deactivate

echo "Job Finished at $(date)"
