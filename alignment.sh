#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --time=1:00:00
#SBATCH --mem=8GB

### input variables
ref=$1
DATA_DIR=$2
file1=$3
file2=$4
RUNDIR=$5
STRAIN=$6
REFSEQ=$7
F1="${DATA_DIR}/${file1}"
F2="${DATA_DIR}/${file2}"

### array set up
cd $RUNDIR
Read1=($(ls $F1*)) #list pair 1 files
Read2=($(ls $F2*)) #list pair 2 files
R1=${Read1[$SLURM_ARRAY_TASK_ID]} #read name associated with slurm task id
R2=${Read2[$SLURM_ARRAY_TASK_ID]}

###check to make sure the names of the reads are the same
N1=${R1#"$F1"} #name of sample
N1=${N1%".fastq.gz"} #may need to change if not zipped

N2=${R2#"$F2"} #name of sample 2
N2=${N2%".fastq.gz"}

if [ "$N1" == "$N2" ]; then
  NAME="$N1"
else
  echo "Names are not the same"
fi


### trim reads ###
module purge
java -jar /share/apps/trimmomatic/0.36/trimmomatic-0.36.jar PE -phred33 -threads 20 ${R1} ${R2} ${NAME}_trimmed_1.fq ${NAME}.unpair_trimmed_1.fq ${NAME}_trimmed_2.fq ${NAME}.unpair_trimmed_2.fq ILLUMINACLIP:/share/apps/trimmomatic/0.36/adapters/NexteraPE-PE.fa:2:30:10:8:true LEADING:20 TRAILING:20 SLIDINGWINDOW:4:20 MINLEN:20

### align trimmed readFilesIn
module load star/intel/2.5.3a
STAR --runThreadN 12 --genomeDir ${ref} --readFilesIn ./${NAME}_trimmed_1.fq ./${NAME}_trimmed_2.fq --outReadsUnmapped Fastx --outFileNamePrefix ${NAME}.${STRAIN}.

### sort and remove duplicate reads ###
module purge
module load pysam/intel/0.10.0
module load samtools/intel/1.6
module load picard/2.8.2

samtools view -bSq 20 ./${NAME}.${STRAIN}.Aligned.out.sam > ./${NAME}.${STRAIN}.star.bam
samtools sort -T ./${NAME}.${STRAIN}.sorted -o ./${NAME}.${STRAIN}.sorted.star.bam ./${NAME}.${STRAIN}.star.bam
samtools index ./${NAME}.${STRAIN}.sorted.star.bam
java -jar $PICARD_JAR MarkDuplicates I=./${NAME}.${STRAIN}.sorted.star.bam O=./${NAME}.${STRAIN}.rmd.star.bam M=./${NAME}.${STRAIN}.met.star.txt REMOVE_DUPLICATES=true
samtools index ./${NAME}.${STRAIN}.rmd.star.bam

### call minor variants ###
python readreport_v4_2.py --strain ${STRAIN} --infile ./${NAME}.${STRAIN}.rmd.star.bam --ref ${REFSEQ}
