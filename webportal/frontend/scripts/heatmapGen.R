capabilities();
args <- commandArgs(trailingOnly = TRUE)

cat("Command-line arguments:", paste(args, collapse = " "), "\n")

if (length(args) >= 2) {
  json_data_input_file <- args[1]
  json_coln_input_file <- args[2]
  json_rown_input_file <- args[3]
  png_output_file <- args[4]

} else {
  cat("Usage: Rscript script.R json_data_input_file output_file\n")
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  install.packages("jsonlite")
}

library(jsonlite)

create_and_save_heatmap <- function(data_json_file, cols_json_file, rows_json_file, output_png) {
  data <- fromJSON(data_json_file)
  rown <- fromJSON(rows_json_file)
  coln <- fromJSON(cols_json_file)
  colors <- colorRampPalette(c("blue", "white", "red"))(100) 
  png(file=output_png,width = 1280, height = 960,units="px", pointsize=12, bg="white", res = NA, type = "quartz")
  p=do.call(cbind, data)
  if (ncol(p)>1){
    gplots::heatmap.2(t(p), trace = "n")
  }else{
    gplots::heatmap.2(t(cbind(p,p)),  Rowv = NA,labRow= "", trace = "n")
  }

  dev.off()
}

create_and_save_heatmap(json_data_input_file, json_coln_input_file, json_rown_input_file, png_output_file)

quit("yes")