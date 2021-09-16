if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Description: Calculate context scores for miRNA
		     using TargetScan methods.

	USAGE:
		./start_targetscan.sh miRNA_file UTR_file ORF_file ContextScoresOutput_file

	EXAMPLE:
		./start_targetscan.sh miR_Family_Info.txt UTR_Sequences.txt ORF_Sequences.txt Targets_output.txt


	Required input files:
		miRNA_file       => mature miRNA data
		UTR_file         => aligned UTRs
		ORF_file         => ORFs corresponding to aligned 3' UTRs
		TA_SPS_FILE      => TA and SPS parameters called 'TA_SPS_by_seed_region.txt'
		CS++ parameters  => Parameters for context++ score model (Agarwal et al., 2015)
				    called 'Agarwal_2015_parameters.txt'
		UTR profiles     => Affected isoform ratios (AIRs) by 3' UTR region
				    called 'All_cell_lines.AIRs.txt'

	Output file:
		ContextScoresOutput_file => Lists context scores and contributions


** Required input files:

	1 - miRNA_file    => mature miRNA information

		contains five fields (tab-delimited):
		miR family  Seed+m8 Species ID  MiRBase ID  Mature sequence


			a. miRNA family ID/name
			b. The 7 nucleotide long seed region sequence.
			c. species ID in which this miRNA has been annotated
			d. ID for this mature miRNA
			e. sequence of this mature miRNA

		ex:
		let-7j-3p  UAUACAG  9031  gga-let-7j-3p  CUAUACAGUCUAUUGCCUUCCU
		miR-1      GGAAUGG  9031  gga-miR-1c     UGGAAUGGAAAGCAGUAUGUAU

	2 - UTR_file      => Aligned UTRs

		contains three fields (tab-delimited):
			a. Gene/UTR ID or name
			b. Species ID for this gene/UTR (must match ID in miRNA file)
			c. Aligned UTR or gene (with gaps from alignment)
		ex:
		BMP8B   9606    GUCCACCCGCCCGGC
		BMP8B   9615    -GUG--CUGCCCACC

		A gene will typically be represented on multiple adjacent lines.


	3 - ORF file      => ORFs matching 3' UTRs in UTR_file

		contains three fields (tab-delimited):
			a. Gene/UTR ID or name
			b. Species ID for this gene/UTR (must match ID in miRNA file)
			c. Aligned ORF (with gaps from alignment or without them)
	"
    exit
fi

MIRNA_FILE=$1
UTR_FILE=$2
ORF_FILE=$3

TMP=`basename $UTR_FILE`
TMP=`echo "$TMP" | cut -d'.' -f1`
echo "$TMP"
TMP="tmp/$TMP"
TS_SITES="${TMP}/targetscan_70_output.txt"
TS_BINS="${TMP}/UTRs_median_BLs_bins.output.txt"
TS_PCT="${TMP}/targetscan_70_output.BL_PCT.output.txt"
TS_ORF_COUNTS="${TMP}/ORF_8mer_counts.txt"
TS_ORF_LENGTHS="${TMP}/ORF.lengths.txt"

TS_CONTEXT="${TMP}/targetscan_70_context_scores_output.txt"

mkdir $TMP

# Process UTR file
echo "processing UTR file ${UTR_FILE}"
exten=`basename $UTR_FILE`
exten="${TMP}/${exten}"
cut -f1,4,5 $UTR_FILE > $exten
UTR_FILE=$exten
echo "processed UTR file to ${UTR_FILE}"

echo "Get site predictions"
perl scripts/targetscan_70.pl $MIRNA_FILE $UTR_FILE $TS_SITES

echo "Get bins"
perl scripts/targetscan_70_BL_bins.pl $UTR_FILE > $TS_BINS

echo "Get PCT"
perl scripts/targetscan_70_BL_PCT.pl $MIRNA_FILE $TS_SITES $TS_BINS > $TS_PCT

echo "processing miRNA file for context++ script ${MIRNA_FILE}"
MIRNA_CONTEXT=`basename $MIRNA_FILE`
MIRNA_CONTEXT="${TMP}/${MIRNA_CONTEXT}"
cut -f1,3,4,5 $MIRNA_FILE > $MIRNA_CONTEXT
echo "processed miRNA file to ${MIRNA_CONTEXT}"

echo "Get ORF info"
perl scripts/targetscan_count_8mers.pl $MIRNA_FILE $ORF_FILE $TS_ORF_LENGTHS >| $TS_ORF_COUNTS

echo "Get context scores"
perl scripts/targetscan_70_context_scores.pl $MIRNA_CONTEXT $UTR_FILE $TS_PCT $TS_ORF_LENGTHS $TS_ORF_COUNTS $TS_CONTEXT

rm -rf $TMP

echo "Your result file is in ${TS_CONTEXT}"
