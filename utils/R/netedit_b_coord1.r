csvfile <- NULL
require(tcltk)
csvfile <- tclvalue(
    tkgetSaveFile(
        filetypes = "{{CSV Files} {.csv}}",
        defaultextension=".csv"
    )
)

if (nchar(csvfile) == 0) {
	stop("Canceled...")
}
print(paste("Saving...", csvfile))

fh <- file(csvfile, "w")
writeChar("\ufeff", fh, eos = NULL)

write.csv(lay_f * 100, file=fh, fileEncoding = "utf-8")

close(fh)
