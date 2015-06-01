        args=commandArgs()[7]

        # Extracting key user specified parameter from 'arg's
        datafile=substr(args, 2, nchar(args))

        print(datafile)


data <- read.table(file=datafile, header=F, na.string="X")
dn <- data$V6==2

postscript(file="projpca.ps", paper="letter", horizontal=T)
plot(data[,7], data[,8], type="p", xlab="PC1", ylab="PC2", main = "HapMapIII + STUDY_TITLE", col = "black")
points(data[dn,7], data[dn,8], col = "red")
abline(h=0.045, col="green")

u <- par("usr")
legend(u[2], u[4], xjust=1, yjust=1, 
legend=c("HapMap", "STUDY_TITLE"),  col=c("black","red"),text.col = c("black", "red"), pch = 19, cex = 1.2)

dev.off()
