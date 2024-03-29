#!/bin/bash
### Exit if command fails
#set -o errexit
### Set readonly variable
#readonly passwd_file=”/etc/passwd”
### exit when variable undefined
#set -o nounset
### Script Root
RootDir=$(cd `dirname $(readlink -f $0)`; pwd)
### MachType
if [ ! -z $(uname -m) ]; then
	machtype=$(uname -m)
elif [ ! -z "$MACHTYPE" ]; then
	machtype=$MACHTYPE
else
	echo "Warnings: unknown MACHTYPE" >&2
fi

#export NUM_THREADS=`grep -c '^processor' /proc/cpuinfo 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1`;
ProgramName=${0##*/}
echo "MachType: $machtype"
echo "RootPath: $RootDir"
echo "ProgName: $ProgramName"
RunPath=$PWD
echo "RunDir: $RunPath"


################# help message ######################################
help() {
cat<<HELP

$0 --- Brief Introduction

Version: 20240228

Requirements:
    LAST (http://last.cbrc.jp/)
    get_the_longest_transcripts.py (https://github.com/xuzhougeng/myscripts)
      python3
    seqkit (https://github.com/shenwei356/seqkit)
    jcvi (https://github.com/tanghaibao/jcvi)
      Biopython (http://www.biopython.org/)
      numpy (http://numpy.scipy.org/)
      matplotlib (http://matplotlib.org/)

Descriptions:
  This script calculate gene synteny and draw the synteny plot
    Source file needed
      1. Protein/CDS/cDNA multifasta file for both query and subject
      2. GFF3 file
    Steps
      1. Convert GFF3 to BED format
        4column: chr[tab]start[tab]end[tab]ID
          seqID should be the same ith multifasta seqID
          Be careful with the sequence names in BED and Fasta
      2. run JCVI to get the raw synteny/anchors
        JCVI use LAST for similarity search
      3. Synteny screen to get high quality anchors
      4. Make synteny plot
      5. Filter 1:1 match for furthr analyais

Options:
  -h   -     Print this help message
  -i1  FILE  Query fasta file in fa.gz or fa format
  -i2  FILE  Subject fasta file in fa.gz or fa format
  -b1  FILE  Query BED format
  -b2  FILE  Subject BED format
  -g1  FILE  Query genome annotation in GFF format
  -g2  FILE  Subject genome annotation in GFF format
  -p1  STR   Query Prefix
  -p2  STR   Subject Prefix
  -ul  -     Use longest transcript for each geneIDs both query and subject
  -ul1 -     Use longest transcript for each query geneIDs
  -ul2 -     Use longest transcript for each subject geneIDs
  -uc1 FILE  Use specified chromosome IDs for analysis in -g1
  -uc2 FILE  Use specified chromosome IDs for analysis in -g2
  -d   DIR   Output directory, default: .
  -mt  STR   Molecular type: cds/pep, default:pep
  -type STR  GFF feature to be extracted, default: gene
  -key  STR  GFF feature to seqID: ID/Name, default: ID
  -cc  FLOAT csscore cutoff for jcvi.compara.catalog ortholog, default: 0.7
  -nsn  -    Do not strip alternative splicing (e.g. At5g06540.1 ->
          At5g06540) [default: False]
          --no_strip_names jcvi.compara.catalog ortholog
  -mp  INT   minspan for jcvi.compara.synteny screen, default: 0
                Only blocks with span >= [default: 0]
  -mz  INT   minsize for jcvi.compara.synteny screen, default: 0
                Only blocks with anchors >= [default: 0]
  -clean -   Clean Temporary files:
                * lastdb files



Example:
  $0 \\
      -i1 ./sp1.fa.gz -i2 ./sp2.fa.gz -g1 ./sp1.gff.gz -g2 ./sp2.gff.gz \\
      -p1 sp1 -p2 sp2 -mt pep -type gene -key ID -mp 30 -mz 10

Author:
  Fu-Hao Lu
  Professor, PhD
  State Key Labortory of Crop Stress Adaptation and Improvement
  College of Life Science
  Jinming Campus, Henan University
  Kaifeng 475004, P.R.China
  E-mail: lufuhao@henu.edu.cn
HELP
exit 0
}
[ $# -lt 1 ] && help
[ "$1" = "-h" ] || [ "$1" = "--help" ] && help
#################### Environments ###################################
echo -e "\n######################\nProgram $ProgramName initializing ...\n######################\n"
#echo "Adding $RunDir/bin into PATH"
#export PATH=$RunDir/bin:$RunDir/utils/bin:$PATH

#################### Initializing ###################################
opt_d=$PWD;
opt_type="gene";
opt_key="ID";
opt_mt="pep"
opt_cc=0.7
opt_nsn=0
opt_mp=0
opt_mz=0
opt_clean=0
opt_testLongest=0;
opt_useLongest=0;
opt_useQueryL=0;
opt_useSubjectL=0;
opt_uc1="";
opt_uc2="";
opt_BEDfil=0;
opt_i1="";
opt_i2="";
opt_b1="";
opt_b2="";
opt_g1="";
opt_g2="";


#################### Parameters #####################################
while [ -n "$1" ]; do
  case "$1" in
    -h) help;shift 1;;
    -i1) opt_i1=$2;shift 2;;
    -i2) opt_i2=$2;shift 2;;
    -b1) opt_b1=$2;shift 2;;
    -b2) opt_b2=$2;shift 2;;
    -g1) opt_g1=$2;shift 2;;
    -g2) opt_g2=$2;shift 2;;
    -p1) opt_p1=$2;shift 2;;
    -p2) opt_p2=$2;shift 2;;
    -ul) opt_useLongest=1;opt_testLongest=1;shift;;
    -ul1) opt_useQueryL=1;opt_testLongest=1;shift;;
    -ul2) opt_useSubjectL=1;opt_testLongest=1;shift;;
    -uc1) opt_uc1=$2;opt_BEDfil=1;shift 2;;
    -uc2) opt_uc2=$2;opt_BEDfil=1;shift 2;;
    -d) opt_d=$2;shift 2;;
    -type) opt_type=$2;shift 2;;
    -key)  opt_key=$2;shift 2;;
    -mt)   opt_mt=$2;shift 2;;
    -cc)   opt_cc=$2;shift 2;;
    -nsn)  opt_nsn=1;shift;;
    -mp)   opt_mp=$2;shift 2;;
    -mz)   opt_mz=$2;shift 2;;
    -clean) opt_clean=1; shift;;
    --) shift;break;;
    -*) echo "error: no such option $1. -h for help" > /dev/stderr;exit 1;;
    *) break;;
  esac
done


#################### Subfuctions ####################################
###Detect command existence
CmdExists () {
	if command -v $1 >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}

### checkBedFasta
### check if number of seqs are equal between BED and Fasta
checkBedFasta () {
	local CBFbed=$1;
	local CBFfasta=$2;

	local NumBed=$(grep -v ^'#' $CBFbed | wc -l)
	local NumFasta=$(grep -v ^'>' $CBFbed | wc -l)

	echo -e "\n"
	echo "Total BED  lines: $NumBed in $CBFbed"
	echo "Total Fasta seqs: $NumFasta in $CBFfasta"
	if [ $NumBed -gt 0 ] && [ $NumFasta -gt 0 ] && [ $NumBed -eq $NumFasta ]; then
		return 0
	else
		echo "Warnings: sequence number EQUAL betwen BED and FASTA: $CBFbed : $CBFfasta" >&2
		return 100
	fi
}



#################### Command test ###################################
CmdExists 'lastal'
if [ $? -ne 0 ]; then
	echo "Error: CMD 'lastal' in PROGRAM 'LAST' (http://last.cbrc.jp/) is required but not found.  Aborting..." >&2
	exit 127
fi
CmdExists 'lastdb'
if [ $? -ne 0 ]; then
	echo "Error: CMD 'lastdb' in PROGRAM 'LAST' (http://last.cbrc.jp/) is required but not found.  Aborting..." >&2
	exit 127
fi
if [ $opt_testLongest -eq 1 ]; then
	CmdExists 'get_the_longest_transcripts.py'
	if [ $? -ne 0 ]; then
		echo "Error: script 'get_the_longest_transcripts.py' on https://github.com/xuzhougeng/myscripts is required but not found.  Aborting..." >&2
		exit 127
	fi
	CmdExists 'seqkit'
	if [ $? -ne 0 ]; then
		echo "Error: CMD 'seqkit' in PROGRAM 'seqkit' (https://github.com/shenwei356/seqkit) is required but not found.  Aborting..." >&2
		exit 127
	fi
fi
if [ $opt_BEDfil -eq 1 ]; then
	CmdExists 'jcvi.bed.clean.pl'
	if [ $? -ne 0 ]; then
		echo "Error: script 'jcvi.bed.clean.pl' in PROGRAM 'GeneSyntenyPipeline' (https://github.com/lufuhao/GeneSyntenyPipeline) is required but not found.  Aborting..." >&2
		exit 127
	fi
fi





#################### Defaults #######################################
step=0;
path_data="$opt_d/1.data"
path_ortholog="$opt_d/2.ortholog"
path_synteny="$opt_d/3.synteny"
path_plot="$opt_d/4.plot"
path_1to1="$opt_d/5.1to1"

mt_type=''
if [[ $opt_mt =~ ^[pP][eE][pP]$ ]];then
	opt_mt='pep'
	mt_type='prot'
elif [[ $opt_mt =~ ^[cC][dD][sS]$ ]]; then
	opt_mt='cds'
	mt_type='nucl'
else
	echo "Error: unknown molecular type" >&2
	exit 100
fi
if [ $opt_useLongest -eq 1 ]; then
	echo "Info: -ul was set; both query and subject longest genes would b used"
	opt_useQueryL=1;
	opt_useSubjectL=1;
fi



#################### Input and Output ###############################
opt_i1=$(readlink -m "$opt_i1")
opt_i2=$(readlink -m "$opt_i2")
if [ ! -z "$opt_b1" ]; then
	opt_b1=$(readlink -m "$opt_b1")
fi
if [ ! -z "$opt_b2" ]; then
	opt_b2=$(readlink -m "$opt_b2")
fi
if [ ! -z "$opt_g1" ]; then
	opt_g1=$(readlink -m "$opt_g1")
fi
if [ ! -z "$opt_g2" ]; then
	opt_g2=$(readlink -m "$opt_g2")
fi



#################### Main ###########################################
echo "################# Parameter check ####################"
echo "    -i1    $opt_i1"
echo "    -i2    $opt_i2"
echo "    -b1    $opt_b1"
echo "    -b2    $opt_b2"
echo "    -g1    $opt_g1"
echo "    -g2    $opt_g2"
echo "    -p1    $opt_p1"
echo "    -p2    $opt_p2"
echo "    -ul    $opt_useLongest"
echo "    -ul1   $opt_useQueryL"
echo "    -ul2   $opt_useSubjectL"
echo "    -uc1   $opt_uc1"
echo "    -uc2   $opt_uc2"
echo "    -d     $opt_d"
echo "    -type  $opt_type"
echo "    -key   $opt_key"
echo "    -mt    $opt_mt"
echo "    -cc    $opt_cc"
echo "    -nsn   $opt_nsn"
echo "    -mp    $opt_mp"
echo "    -mz    $opt_mz"
echo "    -clean $opt_clean"
echo -e "\n\n\n"





### Step1: prepare data
((step++));
if [ ! -d $path_data ]; then
	mkdir -p $path_data
else
	echo "Warnings: Step$step: existing path $path_data; Delete this folder if you have new data" >&2
fi
cd $path_data

# prepare bed
echo "Step${step}: Preparing Data"; echo "Step${step}: Preparing Data" >&2;
if [ ! -s $path_data/$opt_p1.bed ]; then
	if [ $opt_useLongest -eq 0 ]; then
		python3 -m jcvi.formats.gff bed --type=$opt_type --key=$opt_key $opt_g1 > $path_data/$opt_p1.bed
		if [ $? -ne 0 ] || [ ! -s $path_data/$opt_p1.bed ]; then
			echo "Error: Step${step}: Failed to convert query GFF to BED" >&2
			echo "CMD used: python2 -m jcvi.formats.gff bed --type=$opt_type --key=$opt_key $opt_g1 > $path_data/$opt_p1.bed"
			exit 100;
		fi
	else
		zcat  $opt_g1 | get_the_longest_transcripts.py | cut -f 2 > $path_data/$opt_p1.longest.genes
		python3 -m jcvi.formats.gff bed --type=$opt_type --key=$opt_key $opt_g1 > $path_data/$opt_p1.all.bed
		grep -f $path_data/$opt_p1.longest.genes $path_data/$opt_p1.all.bed > $path_data/$opt_p1.bed
	fi
else
	echo "Warnings: Step${step}: using existing Query BED: $path_data/$opt_p1.bed" >&2
fi
if [ ! -z "$opt_uc1" ] && [ -s $opt_uc1 ]; then
	mv $path_data/$opt_p1.bed $path_data/$opt_p1.bed.all
	if [ $? -ne 0 ]; then
		echo "Error: failed to rename Query file: $path_data/$opt_p1.bed" >&2
		exit 100
	fi
	jcvi.bed.clean.pl $path_data/$opt_p1.bed.all $opt_uc1 $path_data/$opt_p1.bed
	if [ $? -ne 0 ] || [ ! -s $path_data/$opt_p1.bed ]; then
		echo "Error: failed to clean Query BED file: $path_data/$opt_p1.bed.all" >&2
		exit 100
	fi
fi
echo "#Step${step} Info: top 5 lines of query BED"
head -n 5 $path_data/$opt_p1.bed

if [ ! -s $path_data/$opt_p2.bed ]; then
	if [ $opt_useLongest -eq 0 ]; then
		python3 -m jcvi.formats.gff bed --type=$opt_type --key=$opt_key $opt_g2 > $path_data/$opt_p2.bed
		if [ $? -ne 0 ] || [ ! -s $path_data/$opt_p2.bed ]; then
			echo "Error: Step${step}: Failed to convert subject GFF to BED" >&2
			echo "CMD used: python3 -m jcvi.formats.gff bed --type=$opt_type --key=$opt_key $opt_g2 > $path_data/$opt_p2.bed"
			exit 100;
		fi
	else
		zcat  $opt_g2 | get_the_longest_transcripts.py > $path_data/$opt_p2.longest.genes
		python3 -m jcvi.formats.gff bed --type=$opt_type --key=$opt_key $opt_g2 > $path_data/$opt_p2.all.bed
		grep -f $path_data/$opt_p2.longest.genes $path_data/$opt_p2.all.bed > $path_data/$opt_p2.bed
	fi
else
	echo "Warnings: Step${step}: using existing Subject BED: $path_data/$opt_p2.bed" >&2
fi
if [ ! -z "$opt_uc2" ] && [ -s $opt_uc2 ]; then
	mv $path_data/$opt_p2.bed $path_data/$opt_p2.bed.all
	if [ $? -ne 0 ]; then
		echo "Error: failed to rename Subject file: $path_data/$opt_p2.bed" >&2
		exit 100
	fi
	jcvi.bed.clean.pl $path_data/$opt_p2.bed.all $opt_uc2 $path_data/$opt_p2.bed
	if [ $? -ne 0 ] || [ ! -s $path_data/$opt_p2.bed ]; then
		echo "Error: failed to clean Subject BED file: $path_data/$opt_p2.bed.all" >&2
		exit 100
	fi

fi
echo "#Step${step} Info: top 5 lines pf subject BED"
head -n 5 $path_data/$opt_p2.bed
echo -e "\n\n\n"

# prepare fasta
if [ ! -s $path_data/$opt_p1.$opt_mt ]; then
	if [ $opt_useQueryL -eq 0 ]; then
		if [[ $opt_i1 =~ ^.*\.[gG][zZ]$ ]]; then
			echo "#Step${step} Info: Query in fasta.gz format, decompressing"
			gunzip -c $opt_i1 > $path_data/$opt_p1.$opt_mt
		else
			echo "#Step${step} Info: Query in fasta format, Linking"
			ln -sf $opt_i1 $path_data/$opt_p1.$opt_mt
		fi
	else
		echo "#Step${step} Info: Extracting longest Query transcript IDs"
		if [ ! -s $path_data/$opt_p1.longest.genes ]; then
			zcat  $opt_g1 | get_the_longest_transcripts.py | cut -f 2 > $path_data/$opt_p1.longest.genes
		fi
		seqkit grep -f $path_data/$opt_p1.longest.genes $opt_i1 > $path_data/$opt_p1.$opt_mt
	fi
else
	echo "Warnings: Step${step}: use existing file: $path_data/$opt_p1.$opt_mt; Delete this if you have new data" >&2
fi
if [ ! -z "$opt_uc1" ] && [ -s $opt_uc1 ]; then
	if [ ! -s $path_data/$opt_p1.$opt_mt.all ]; then
		mv $path_data/$opt_p1.$opt_mt $path_data/$opt_p1.$opt_mt.all
		if [ $? -ne 0 ]; then
			echo "Error: failed to rename Query file: $path_data/$opt_p1.$opt_mt" >&2
			exit 100
		fi
	else
		echo "Warnings: existing $path_data/$opt_p1.$opt_mt.all" >&2
	fi
	if [ ! -s $path_data/$opt_p1.$opt_mt.tmplist ]; then
		grep -v ^'#' $path_data/$opt_p1.bed | cut -f 4 | sort -u > $path_data/$opt_p1.$opt_mt.tmplist
	fi
	if [ ! -s $path_data/$opt_p1.$opt_mt ]; then
		seqkit grep -f $path_data/$opt_p1.$opt_mt.tmplist $path_data/$opt_p1.$opt_mt.all > $path_data/$opt_p1.$opt_mt
		if [ $? -ne 0 ] || [ ! -s $path_data/$opt_p1.$opt_mt ]; then
			echo "Error: failed to clean Query BED file: $path_data/$opt_p1.$opt_mt.all" >&2
			exit 100
		fi
	else
		echo "Warnings: existing $path_data/$opt_p1.$opt_mt" >&2
		echo "Warnings: -uc1 option skipped" >&2
	fi
fi
if [ ! -s $path_data/$opt_p2.$opt_mt ]; then
	if [ $opt_useSubjectL -eq 0 ]; then
		if [[ $opt_i2 =~ ^.*\.[gG][zZ]$ ]]; then
			echo "#Step${step} Info: Subject in fasta.gz format, decompressing"
			gunzip -c $opt_i2 > $path_data/$opt_p2.$opt_mt
		else
			echo "#Step${step} Info: Subject in fasta format, Linking"
			ln -sf $opt_i2 $path_data/$opt_p2.$opt_mt
		fi
	else
		echo "#Step${step} Info: Extracting longest Subject transcript IDs"
		if [ ! -s $path_data/$opt_p2.longest.genes ]; then
			zcat  $opt_g2 | get_the_longest_transcripts.py | cut -f 2 > $path_data/$opt_p2.longest.genes
		fi
		seqkit grep -f $path_data/$opt_p2.longest.genes $opt_i2 > $path_data/$opt_p2.$opt_mt
	fi
else
	echo "Warnings: Step${step}: use existing file: $path_data/$opt_p2.$opt_mt; Delete this if you have new data" >&2
fi
if [ ! -z "$opt_uc2" ] && [ -s $opt_uc2 ]; then
	if [ ! -s $path_data/$opt_p2.$opt_mt.all ]; then
		mv $path_data/$opt_p2.$opt_mt $path_data/$opt_p2.$opt_mt.all
		if [ $? -ne 0 ]; then
			echo "Error: failed to rename Query file: $path_data/$opt_p2.$opt_mt" >&2
			exit 100
		fi
	else
		echo "Warnings: existing $path_data/$opt_p2.$opt_mt.all" >&2
		echo "Warnings: -uc2 option skipped" >&2
	fi
	if [ ! -s $path_data/$opt_p2.$opt_mt.tmplist ]; then
		grep -v ^'#' $path_data/$opt_p2.bed | cut -f 4 | sort -u > $path_data/$opt_p2.$opt_mt.tmplist
	fi
	if [ ! -s $path_data/$opt_p2.$opt_mt ]; then
		seqkit grep -f $path_data/$opt_p2.$opt_mt.tmplist $path_data/$opt_p2.$opt_mt.all > $path_data/$opt_p2.$opt_mt
		if [ $? -ne 0 ] || [ ! -s $path_data/$opt_p2.$opt_mt ]; then
			echo "Error: failed to clean Query BED file: $path_data/$opt_p2.$opt_mt.all" >&2
			exit 100
		fi
	else
		echo "Warnings: existing $path_data/$opt_p2.$opt_mt" >&2
		echo "Warnings: -uc1 option skipped" >&2
	fi
fi
### double check sequence
if checkBedFasta $path_data/$opt_p1.bed $path_data/$opt_p1.$opt_mt; then
	echo "Info: equal Query seq number between $path_data/$opt_p1.bed and $path_data/$opt_p1.$opt_mt"
else
	echo "Warnings: ineuqal Query seq number between $path_data/$opt_p1.bed and $path_data/$opt_p1.$opt_mt" >&2
fi
if checkBedFasta $path_data/$opt_p2.bed $path_data/$opt_p2.$opt_mt; then
	echo "Info: equal Subject seq number between $path_data/$opt_p1.bed and $path_data/$opt_p2.$opt_mt"
else
	echo "Warnings: ineuqal Subject seq number between $path_data/$opt_p1.bed and $path_data/$opt_p2.$opt_mt" >&2
fi

echo -e "\n\n\n"



### Step2: run JCVI
((step++));
if [ ! -d $path_ortholog ]; then
	mkdir -p $path_ortholog
else
	echo "Warnings: Step${step}: existing path $path_ortholog; Delete this folder if you have new data" >&2
fi
cd $path_ortholog
echo "Step${step}: run jcvi.compara.catalog ortholog"; echo "Step${step}: run jcvi.compara.catalog ortholog" >&2;
if [ ! -s $path_ortholog/$opt_p1.$opt_p2.anchors ]; then
	ln -sf $path_data/$opt_p1.bed $path_ortholog/$opt_p1.bed
	ln -sf $path_data/$opt_p2.bed $path_ortholog/$opt_p2.bed
	ln -sf $path_data/$opt_p1.$opt_mt $path_ortholog/$opt_p1.$opt_mt
	ln -sf $path_data/$opt_p2.$opt_mt $path_ortholog/$opt_p2.$opt_mt

	CatalogOptions=""
	if [ $opt_nsn -eq 1 ]; then
		CatalogOptions="--no_strip_names"
	fi
	python3 -m jcvi.compara.catalog ortholog $opt_p1 $opt_p2 $CatalogOptions --dbtype $mt_type --cscore=$opt_cc > $opt_p1.$opt_p2.compara.catalog.ortholog.log 2>&1
	if [ $? -ne 0 ] || [ ! -s $path_ortholog/$opt_p1.$opt_p2.anchors ]; then
		echo "Error: Step${step}: jcvi.compara.catalog ortholog running error" >&2
		echo "CMD used: python3 -m jcvi.compara.catalog ortholog $opt_p1 $opt_p2 $CatalogOptions --dbtype $mt_type --cscore=$opt_cc" >&2
		exit 100
	fi
fi
if [ $opt_clean -eq 1 ]; then
	rm *.bck *.des *.prj *.sds *.ssp *.suf *.tis
fi

#Pairwise synteny visualization using dot plot.
if [ ! -s $opt_p1.$opt_p2.anchors.dotplot.pdf ]; then
	python3 -m jcvi.graphics.dotplot $opt_p1.$opt_p2.anchors -o $opt_p1.$opt_p2.anchors.dotplot.pdf --dpi=600 --format=pdf --font=Arial > $opt_p1.$opt_p2.graphics.dotplot.log 2>&1
fi

#We could also quick test if the synteny pattern is indeed 1:1, by running:
if [ ! -s $opt_p1.$opt_p2.depth.pdf ]; then
	python3 -m jcvi.compara.synteny depth --histogram $opt_p1.$opt_p2.anchors > $opt_p1.$opt_p2.compara.synteny.depth.log 2>&1
fi
echo -e "\n\n\n"



### Step3. synteny
((step++));
if [ ! -d $path_synteny ]; then
	mkdir -p $path_synteny
else
	echo "Warnings: Step${step}: existing path $path_synteny; Delete this folder if you have new data" >&2
fi
cd $path_synteny
echo "Step${step}: run jcvi.compara.synteny screen"; echo "Step${step}: run jcvi.compara.synteny screen" >&2;
ln -sf $path_ortholog/$opt_p1.$opt_p2.anchors $path_synteny/$opt_p1.$opt_p2.anchors
ln -sf $path_data/$opt_p1.bed $path_synteny/$opt_p1.bed
ln -sf $path_data/$opt_p2.bed $path_synteny/$opt_p2.bed
if [ ! -s $opt_p1.$opt_p2.anchors.new ]; then
	python3 -m jcvi.compara.synteny screen --minspan=$opt_mp --simple --minsize=$opt_mz $opt_p1.$opt_p2.anchors $opt_p1.$opt_p2.anchors.new > $opt_p1.$opt_p2.compara.synteny.screen.log 2>&1
	if [ $? -ne 0 ] || [ ! -s $path_synteny/$opt_p1.$opt_p2.anchors.new ] || [ ! -s $path_synteny/$opt_p1.$opt_p2.anchors.simple ]; then
		echo "Error: Step${step}: jcvi.compara.synteny screen running error" >&2
		echo "CMD used: python3 -m jcvi.compara.synteny screen --minspan=$opt_mp --simple --minsize=$opt_mz $opt_p1.$opt_p2.anchors $opt_p1.$opt_p2.anchors.new" >&2
		exit 100
	fi
fi
echo -e "\n\n\n"



### Step4. plot
((step++));
if [ ! -d $path_plot ]; then
	mkdir -p $path_plot
else
	echo "Warnings: Step${step}: existing path $path_plot; Delete this folder if you have new data" >&2
fi
cd $path_plot
echo "Step${step}: run jcvi.graphics.karyotype"; echo "Step${step}: run jcvi.graphics.karyotype" >&2;

ln -sf $path_data/$opt_p1.bed $path_plot/$opt_p1.bed
ln -sf $path_data/$opt_p2.bed $path_plot/$opt_p2.bed
ln -sf $path_synteny/$opt_p1.$opt_p2.anchors.simple $path_plot/

#seqids
if [ ! -s $path_plot/$opt_p1.$opt_p2.seqids ]; then
	cut -f 1 $opt_p1.bed | sort -u | tr "\n" "," | sed 's/,$/\n/' > $path_plot/$opt_p1.$opt_p2.seqids
	if [ $? -ne 0 ] || [ ! -s $path_plot/$opt_p1.$opt_p2.seqids ]; then
		echo "Error: Step${step}: Failed to collect query seqIDs for $opt_p1" >&2
		exit 100
	fi
	cut -f 1 $opt_p2.bed | sort -u | tr "\n" "," | sed 's/,$/\n/' >> $path_plot/$opt_p1.$opt_p2.seqids
	if [ $? -ne 0 ] || [ ! -s $path_plot/$opt_p1.$opt_p2.seqids ]; then
		echo "Error: Step${step}: Failed to collect subject seqIDs for $opt_p2" >&2
		exit 100
	fi
fi

#layout
#The whole canvas is 0-1 on x-axis and 0-1 on y-axis. Then ,
# col 1,2,3: three columns specify the position of the track.
# col 4: rotation
# col 5: color
# col 6: label
# col 7: vertical alignment (va): top/bottom/center
# col 8: the genome BED file.
# col 9: top/bottom/center
#The next stanza specifies what edges to draw between the tracks
# col1,2,3: e, 0, 1 asks to draw edges between track 0 and 1
# col 4: using information from the .simple file.
#            只需要将想要高亮的那一行syntenic relationship的行首加g*，其中g代表绿色，也可以改成r*,那样就成了红色
if [ ! -s $path_plot/$opt_p1.$opt_p2.layout ]; then
	echo "# y, xstart, xend, rotation, color, label, va, bed, label_va" > $path_plot/$opt_p1.$opt_p2.layout
	echo ".6,     .1,    .8,       0,      m, $opt_p1, top, $opt_p1.bed, center" >> $path_plot/$opt_p1.$opt_p2.layout
	echo ".4,     .1,    .8,       0,      k, $opt_p2, bottom, $opt_p2.bed, center" >> $path_plot/$opt_p1.$opt_p2.layout
	echo "# edges" >> $path_plot/$opt_p1.$opt_p2.layout
	echo "e, 0, 1, $opt_p1.$opt_p2.anchors.simple" >> $path_plot/$opt_p1.$opt_p2.layout
fi

#utils/webcolors.py
#perl -i -lane '$i="";$j=""; $line=$_; $F[0]=~s/^.*\*//; if ($F[0]=~/$TraesCS(\d+)[ABD]\d+G\d+$/) {$i=$1;}else{print STDERR "Error: no match1";} if ($F[2]=~/$TraesCS(\d+)[ABD]\d+G\d+$/) {$j=$1;}else{print STDERR "Error: no match2";} print STDERR "Info: i: $i; j : $j"; if ($i eq $j) {$line="red*".$line;}else{$line="black*".$line;} print $line;' aa.bb.anchors.simple

if [ ! -s $path_plot/$opt_p1.$opt_p2.pdf ]; then
	python3 -m jcvi.graphics.karyotype --dpi=600 --format=pdf  --keep-chrlabels --font=Arial --outfile $path_plot/$opt_p1.$opt_p2.cscore-$opt_cc.pdf $path_plot/$opt_p1.$opt_p2.seqids $path_plot/$opt_p1.$opt_p2.layout > $opt_p1.$opt_p2.graphics.karyotype.pdf.log 2>&1
	if [ $? -ne 0 ] || [ ! -s "$path_plot/$opt_p1.$opt_p2.cscore-$opt_cc.pdf" ]; then
		echo "Error: Step${step}: Failed to run jcvi.graphics.karyotype for seqids: $path_plot/$opt_p1.$opt_p2.seqids layout:$path_plot/$opt_p1.$opt_p2.layout" >&2
		echo "CMD used: python3 -m jcvi.graphics.karyotype --dpi=600  --keep-chrlabels --format=pdf --font=Arial --outfile $path_plot/$opt_p1.$opt_p2.cscore-$opt_cc.pdf $path_plot/$opt_p1.$opt_p2.seqids $path_plot/$opt_p1.$opt_p2.layout"
		exit 100
	fi
	python3 -m jcvi.graphics.karyotype --dpi=600 --format=eps  --keep-chrlabels --font=Arial --outfile $path_plot/$opt_p1.$opt_p2.cscore-$opt_cc.eps $path_plot/$opt_p1.$opt_p2.seqids $path_plot/$opt_p1.$opt_p2.layout > $opt_p1.$opt_p2.graphics.karyotype.eps.log 2>&1
	python3 -m jcvi.graphics.karyotype --dpi=600 --format=png  --keep-chrlabels --font=Arial --outfile $path_plot/$opt_p1.$opt_p2.cscore-$opt_cc.png $path_plot/$opt_p1.$opt_p2.seqids $path_plot/$opt_p1.$opt_p2.layout > $opt_p1.$opt_p2.graphics.karyotype.png.log 2>&1
fi
echo -e "\n\n\n"



### Step5. 1:1
((step++));
if [ ! -d $path_1to1 ]; then
	mkdir -p $path_1to1
else
	echo "Warnings: Step${step}: existing path $path_1to1; Delete this folder if you have new data" >&2
fi
cd $path_1to1
echo "Step${step}: run  1:1 synteny"; echo "Step${step}: run 1:1 synteny" >&2;

#ln -sf $path_synteny/$opt_p1.$opt_p2.anchors.new $path_1to1/
SimpleFile=$path_synteny/$opt_p1.$opt_p2.anchors.new

if [ ! -s $opt_p1.$opt_p2.duplicated.list ]; then
	grep -v ^'#' $SimpleFile | cut -f 1 | sort | uniq -d > $opt_p1.$opt_p2.duplicated.list
	grep -v ^'#' $SimpleFile | cut -f 2 | sort | uniq -d >> $opt_p1.$opt_p2.duplicated.list
fi
if [ -s $opt_p1.$opt_p2.duplicated.list ]; then
	if [ ! -s $path_1to1/$opt_p1.$opt_p2.anchors.new.uniq ]; then
		grep -v -f $opt_p1.$opt_p2.duplicated.list $SimpleFile > $path_1to1/$opt_p1.$opt_p2.anchors.new.uniq
	fi
	LineNum1=$(grep -v ^'#' $SimpleFile | wc -l)
	LineNum2=$(cat $opt_p1.$opt_p2.duplicated.list | wc -l)
	LineNum3=$(grep -v ^'#' $path_1to1/$opt_p1.$opt_p2.anchors.new.uniq | wc -l)
	echo "Info: geneIDs with duplication: $LineNum1"
	echo "Info: duplication IDs         : $LineNum2"
	echo "Info: geneIDs uniq            : $LineNum3"
	echo "Info: final uniq synteny: $path_1to1/$opt_p1.$opt_p2.anchors.new.uniq"
else
	grep -v ^'#' $SimpleFile | wc -l
	cat $opt_p1.$opt_p2.duplicated.list | wc -l
	echo "Info: no duplicated geneIDs detected, final uniq synteny: $SimpleFile"
fi

#list.merger.pl Final.AABBDD.uniq "undef" final.uniq dd.aa.anchors.new.uniq dd.bb.anchors.new.uniq

echo -e "\n\n\n### DONE ###\n"
exit 0
