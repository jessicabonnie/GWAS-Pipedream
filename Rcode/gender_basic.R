print("#########################################################################")
print("#")
print("# GWAS-Pipedream - Standard GWAS QC Pipeline Package")
print("# (c) 2014-2015 JBonnie, WMChen")
print("# Script: gender_basic.R -- colors by gender, counts mislabelled samples")
print("# Usage: gender_basic.R <path to 'bySample' table from King> <nickname for prefixing file> <Overall Study Title")
print("#")
print("#########################################################################")

## Read in arguments
args <- commandArgs(TRUE)
print(args)
table_loc <- as.character(args[1])
nickname <- as.character(args[2])
overall_title <- gsub("_"," ",as.character(args[3]))

data.raw <- read.table(file = table_loc, header=T)

## We will use these values to determine which samples have been mislabelled and which ones need to be removed because they are bad
ysnp_count<-max(data.raw$N_ySNP)
#sixthy<-ysnp_count/6
#fivesixthy<-5*sixthy
#thirdy<-ysnp_count/3
#twothirdy<-2*thirdy
half_count <- ysnp_count/2



postscript(paste0(nickname,"gender.ps"), paper="letter", horizontal=T)
#jpeg("gender.jpg",width=800, height=800)

N <- sum((data.raw$SEX==1 & data.raw$N_ySNP < half_count) | (data.raw$SEX==2 & data.raw$N_ySNP>half_count) )
#N <- sum((data.raw$SEX==1 & data.raw$N_ySNP < 700) | (data.raw$SEX==2 & data.raw$N_ySNP>700) )
text <- paste(sep="", "Gender Checking in ", overall_title, " Samples (", N, " Samples Mislabeled)")
plot(data.raw$N_ySNP[data.raw$SEX==2], data.raw$xHeterozygosity[data.raw$SEX==2], type="p",
     col = "red", xlim=c(0,max(data.raw$N_ySNP)), ylim=c(0,max(data.raw$xHeterozygosity)),
     main = text,
     xlab="# Y-Chr SNPs", ylab = "X-Chr Heterozygosity")
points(data.raw$N_ySNP[data.raw$SEX==1], data.raw$xHeterozygosity[data.raw$SEX==1], col = "blue")
points(data.raw$N_ySNP[data.raw$SEX==2 & data.raw$N_ySNP>half_count], data.raw$xHeterozygosity[data.raw$SEX==2 & data.raw$N_ySNP>half_count], col = "red")
points(data.raw$N_ySNP[data.raw$SEX==0], data.raw$xHeterozygosity[data.raw$SEX==0], col = "black")

u <- par("usr")
legend(u[2], u[4], xjust=1, yjust=1, 
       legend=c("Female", "Male", "Unknown"), col=c("red", "blue", "black"),
       text.col = c("red", "blue", "black"), pch = 19, cex = 1.2)

dev.off()
