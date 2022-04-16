# GeneSyntenyPipeline

    SCR_018198

This pipeline was designed to 

   - [X] draw gene synteny plot between genomes

   - [X] obtain 1 to 1 genepairs from each genome

>    Source file needed

>      1. Protein/CDS/cDNA multifasta file for both query and subject

>      2. GFF3/BED file

>    Steps

>      1. Convert GFF3 to BED format

>        4column: chr[tab]start[tab]end[tab]ID

>          ID should be the same with multifasta seqID

>      2. run JCVI to get the raw synteny/anchors

>        JCVI use LAST for similarity search

>      3. Synteny screen to get high quality anchors

>      4. Make synteny plot

>      5. Filter 1:1 match for furthr analyais

---

## Requirements:

   + [X] [LAST](http://last.cbrc.jp/)

   + [X] [get_the_longest_transcripts.py](https://github.com/xuzhougeng/myscripts)

      * [X] python3

   + [X] [seqkit](https://github.com/shenwei356/seqkit)

   + [X] [JCVI](https://github.com/tanghaibao/jcvi)

---

## Options:

### jcvi.pipeline.sh

>  -h    Print this help message

>  -i1   Query fasta file in fa.gz or fa format

>  -i2   Subject fasta file in fa.gz or fa format

>  -g1   Query genome annotation in GFF format

>  -g2   Subject genome annotation in GFF format

>  -p1   Query Prefix

>  -p2   Subject Prefix

>  -ul   Use longest transcript for each geneIDs both query and subject

>  -ul1  Use longest transcript for each query geneIDs

>  -ul2  Use longest transcript for each subject geneIDs 

>  -d    Output directory, default: .

>  -mt   Molecular type: cds/pep, default:pep

>  -type GFF feature to be extracted, default: mRNA

>  -key  GFF feature to seqID: ID/Name, default: ID

>  -cc   csscore cutoff for jcvi.compara.catalog ortholog, default: 0.7

>  -nsn  Do not strip alternative splicing (e.g. At5g06540.1 ->

>          At5g06540) [default: False]

>          --no_strip_names jcvi.compara.catalog ortholog

>  -mp   minspan for jcvi.compara.synteny screen, default: 0

>  -mz   minsize for jcvi.compara.synteny screen, default: 0

>  -clean Clean Temporary files:

>            * lastdb files

Example:

```bash
  ./jcvi.pipeline.sh \
      -i1 ./sp1.fa.gz -i2 ./sp2.fa.gz -g1 ./sp1.gff.gz -g2 ./sp2.gff.gz \
      -p1 sp1 -p2 sp2 -fmt pep -type mRNA -key ID -mp 30 -mz 10
```

### jcvi.bed.ID.convert.pl

> This script is used to convert JCVI jcvi.formats.gff bed col4 to a new ID

    ### jcvi.bed1 input

    chr[tab]start[tab]end[tab]ID_bed1[tab]0[tab]strand

    

    ### convertfile ID list [2 columns]

    ID_bed1[tab]new_ID_bed2

    

    ### jcvi.bed2 out
    
    chr[tab]start[tab]end[tab]new_ID_bed2[tab]0[tab]strand

Example

```bash
jcvi.bed.ID.convert.pl jcvi.bed1 convertfile jcvi.bed2
```

---

## Author:

    Fu-Hao Lu

    Professor, PhD

    State Key Labortory of Crop Stress Adaptation and Improvement

    College of Life Science

    Jinming Campus, Henan University

    Kaifeng 475004, P.R.China

    E-mail: lufuhao@henu.edu.cn
