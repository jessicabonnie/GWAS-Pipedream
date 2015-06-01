        args=commandArgs()[7]

        # Extracting key user specified parameter from 'arg's
        datafile=substr(args, 2, nchar(args))

        print(datafile)


data <- read.table(file = datafile, header=T)

postscript("samplecallrate.ps", paper="letter", horizontal=T)
par(mfrow=c(2,1))
x <- 1-data$Missing
hist(x, xlab = "Call Rate", main = "Histogram of Sample Call Rate in STUDY_TITLE ExomeChip Data")
abline(v=0.95, col="red")
hist(x[x>0.94 & x < 0.99], xlim=c(0.94,0.99), xlab = "Call Rate", main = "Call Rate Between 94% and 99%")     
abline(v=0.95, col="red")

par(mfrow=c(1,1))
x <- data$Heterozygosity
hist(x, xlab="Heterozygosity", main="Histogram of Heterozygosity in STUDY_TITLE ExomeChip Data")

x <- 1-data$Missing
y <- data$Heterozygosity
plot(x, y, xlab="Call Rate", ylab="Heterozygosity", main="Sample Level QC in STUDY_TITLE ExomeChip Data", col="green")
abline(v=0.95, col="red")
dev.off()

