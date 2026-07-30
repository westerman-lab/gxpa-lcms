rm -rf *.png *.html *_files *_cache
if [ "$1" == "full" ]; then
  rm -rf bcftools htslib phenotypes metabolomics analysis_df.csv
fi
  
