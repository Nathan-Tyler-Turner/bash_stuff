#!/bin/bash
set -eo pipefail

# Check number of arguments is 1, if not print usage
if [[ "$#" -ne 1 ]]; then
    echo "Usage: docker run --rm -v $(pwd):$(pwd) -w $(pwd) -u $(id -u):$(id -g) sixpack input.fasta"
    exit 1
fi

# Check that required executables exist. This is helpful for interactive debugging using a conda environment.
if ! command -v transeq &> /dev/null; then echo "ERROR: transeq not found"; exit 1; fi
if ! command -v getorf &> /dev/null; then echo "ERROR: getorf not found"; exit 1; fi
if ! command -v orfm &> /dev/null; then echo "ERROR: orfm not found"; exit 1; fi

## Get the basename of the first thing passed to docker container at runtime
infile=$(basename "$1")

# Make sure the input file exists
if [[ ! -f $infile ]]; then
    echo "ERROR: File doesn't exist: ${infile}" 
    exit 1
fi

# Get the extension. First remove a GZ if one exists, then get the extension and set to lowercase.
# https://stackoverflow.com/a/22957485
inext=$(echo ${infile} | sed 's/\.gz$//g')
# https://stackoverflow.com/a/965069
inext="${inext##*.}"
# Set to lower
inext=$(echo "$inext" | awk '{print tolower($0)}')

# Check that the file extension is supported. Regex must be a variable (if backslashes) or unquoted for POSIX-compliance.
if ! [[ $inext =~ ^(fasta|fa|fastq|fq)$ ]]; then
    echo "ERROR: Input must be a FASTA (.fasta, .fa) or FASTQ (.fastq, .fq) file: ${infile}"
    echo "ERROR: Detected file extension: ${inext}"
    exit 1
fi

# Set a default ORF minimum length here
if [[ -z "${minlen}" ]]; then minlen="30"; fi

# Set a default ORF finder here
if [[ -z "${orffinder}" ]]; then orffinder="getorf"; fi

# Check minimum length is a number
if [[ ! $minlen =~ ^[0-9]+$ ]] ; then
   echo "ERROR: minlen is not a number: ${minlen}" 
   exit 1
fi

# FIXME check that the number is a multiple of three
if (( $minlen % 3 != 0 )); then
   echo "ERROR: minlen is not a multiple of 3: ${minlen}" 
   exit 1
fi

# Check orffinder is getorf or orfm
if [[ ! $orffinder =~ ^(getorf|orfm)$ ]] ; then
   echo "ERROR: Invalid orffinder: ${orffinder}" 
   exit 1
fi

# Set a default ORF table here
if [[ -z "${codontable}" ]]; then 
    if [[ $orffinder == "getorf" ]]; then
        codontable="0"
    elif [[ $orffinder == "orfm" ]]; then
        codontable="1"
    fi
fi

# Check validity of codon tables, limiting to only what's available in EMBOSS TranSeq and OrfM
validcodes=(0 1 2 3 4 5 6 9 10 11 12 13 14 16 21 22 23)
if [[ ! "${validcodes[*]}" =~ "${codontable}" ]]; then 
    echo "ERROR: invalid codon table: ${codontable}. Valid choices: 0,1,2,3,4,5,6,9,10,11,12,13,14,16,21,22,23"
    # exit 1
fi

# Set output file names
outproteins=${infile}.sixpack.proteins.faa
outorfs=${infile}.sixpack.orfs.faa
outlog=${infile}.sixpack.log.txt
outrev=${infile}.sixpack.reverse.complement.faa

# Log to stdout and log file
echo "Sixpack analysis started: $(date)" | tee $outlog
echo "Input file: ${infile}" | tee -a $outlog
echo "Input file type: ${inext}" | tee -a $outlog
echo "Output proteins: ${outproteins}" | tee -a $outlog
echo "Output ORFs: ${outorfs}" | tee -a $outlog
echo "Output log file: ${outlog}" | tee -a $outlog
echo "Minimum ORF length: ${minlen}" | tee -a $outlog
echo "Codon table: ${codontable}" | tee -a $outlog
echo "ORF finder: ${orffinder}" | tee -a $outlog

# Six frame translation with EMBOSS transeq
echo "Six-frame translation started $(date)" | tee -a $outlog
transeq -auto -sequence $infile -outseq $outproteins -frame 6
echo "Six-frame translation finished $(date)" | tee -a $outlog

# Reverse complement generation of sequence with EMBOSS revseq
revseq -sequence $infile -outseq $outrev
echo "Reverse complement of input file generated $(date)" | tee -a $outlog

# ORF finding with either getorf or orfm
echo "ORF finding started $(date)" | tee -a $outlog
if [[ ${orffinder} =~ "getorf" ]]; then
    getorf -auto -sequence $infile -outseq $outorfs -minsize $minlen -table $codontable
elif [[ ${orffinder} =~ "orfm" ]]; then 
    orfm -m $minlen -c $codontable $infile > $outorfs
else
    echo "ERROR: Invalid orffinder: ${orffinder}" | tee -a $outlog
    exit 1
fi
echo "ORF finding finished $(date)" | tee -a $outlog

# Analysis is complete!
echo "Sixpack analysis finished: $(date)" | tee -a $outlog