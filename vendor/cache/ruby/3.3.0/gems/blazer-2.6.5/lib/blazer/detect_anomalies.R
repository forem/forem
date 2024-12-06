tryCatch({
  library(AnomalyDetection)

  args <- commandArgs(trailingOnly = TRUE)

  con <- textConnection(args[2])
  data <- read.csv(con, stringsAsFactors = FALSE)
  data$timestamp <- as.POSIXct(data$timestamp)

  if (identical(args[1], "ts")) {
    res <- AnomalyDetectionTs(data, direction = "both", alpha = 0.05, max_anoms = 0.2)
  } else {
    res <- AnomalyDetectionVec(data$count, direction = "both", alpha = 0.05, max_anoms = 0.2, period = length(data$count) / 2 - 1)
  }

  write.csv(res$anoms)
}, error = function (e) {
  write.csv(geterrmessage())
})
