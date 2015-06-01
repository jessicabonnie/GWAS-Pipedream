        args=commandArgs()[7]

        # Extracting key user specified parameter from 'arg's
        datafile=substr(args, 2, nchar(args))

        print(datafile)


data <- read.table(file=datafile, header=F, na.string="X")
dn <- data$V6==2

postscript(file="EURprojpca.ps", paper="letter", horizontal=T)
plot(data[,7], data[,8], type="p", xlab="PC1", ylab="PC2", main = "CEU/TSI + STUDY_TITLE", col = "black")
points(data[dn,7], data[dn,8], col = "red")
abline(v=0, col="green")

u <- par("usr")
legend(u[2], u[4], xjust=1, yjust=1, 
legend=c("CEU+TSI", "STUDY_TITLE"),  col=c("black","red"),text.col = c("black", "red"), pch = 19, cex = 1.2)

dev.off()
