#!/bin/sh

#### USER CHANGES THESE VARIABLES DEPENDING ON RUN ######
JOB_NAME="FLU"
FASTQ_DIR="/scratch/kej310/practice/rawfiles"
REF="/scratch/kej310/practice/reference/h1n1/"
FASTQ1="000000000-CHT9C_l01_n01_"
FASTQ2="000000000-CHT9C_l01_n02_"
RUNDIR="/scratch/kej310/practice"
STRAIN="h1n1" #lowercase strain name
REFSEQ="/scratch/kej310/practice/reference/h1n1/cal_07_09_seg_cds_MP_NS.fasta"
array=0-1 #NUMBER OF FASTQS


### DO NOT CHANGE BELOW HERE ###
cd ${RUNDIR}
sbatch --job-name=$JOB_NAME -a ${array} alignment.sh ${REF} ${FASTQ_DIR} ${FASTQ1} ${FASTQ2} ${RUNDIR} ${STRAIN} ${REFSEQ}
