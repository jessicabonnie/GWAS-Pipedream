postscript("rawrel.ps", paper="letter", horizontal=T)

data <- read.table(file = "dn5.kin0", header=T)

plot(data$IBS0[data$Kinship > 0.02], data$Kinship[data$Kinship > 0.02], type="p",
            col = "blue", cex.lab=1.3,
            main = "Relationship in STUDY_TITLE Across Families",
            xlab="Proportion of Zero IBS", ylab = "Estimated Kinship Coefficient")

abline(h = 0.3536, col = "red", lty = 3)
abline(h = 0.1768, col = "green", lty = 3)
abline(h = 0.0884, col = "gold", lty = 3)
abline(h = 0.0442, col = "blue", lty = 3)

dev.off()



