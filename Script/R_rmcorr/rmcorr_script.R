# Script used for performing the rmcorr analysis with a within-subject (N = 12) designed and 3 levels (PL0, PL50, PL95)
# It load the data from the xlsx file, run the analysis and create the colorful figure.
# the p-value is adjusted as p * number of correlation/test.
# Author: Paolo Tecchio

#Load library
library("readxl")
library(rmcorr)
library(Hmisc)
library(ggplot2)

#close plots
#dev.off()

num_test = 3 #adjust p-value according to the number of tests i.e. Bonferroni Post Hoc correction

#pick up file
my_data <- read_excel(file.choose())

#set color(s) and create figure for plots
RColorBrewer::brewer.pal(12,'Paired') #12 because 12 subjects
myPal <- colorRampPalette(RColorBrewer::brewer.pal(12,'Paired'))
par(mfrow=c(1,3), mgp = c(2.5, .75, 0), mar = c(4,4,2,1), cex = 1.2)

labelY <- expression("rFE["~'%' ~ REF[TOR] ~ "]")

#1st rmcorr - Fascicle stretch up to peak fascicle force - peak fascicle force effect
matdata <- data.frame(cbind(my_data$Subj, my_data$Fst_Fas_Force, my_data$Fas_Force))
Fstretch.rmc <- rmcorr(my_data$Subj, my_data$Fst_Fas_Force, my_data$Fas_Force, matdata)
print("Fascicle stretch up to peak fascicle force - peak fascicle force RMCORR")
print(Fstretch.rmc)
print("Adjusted p-value: ")
print(Fstretch.rmc$p * num_test) #print adjusted p value

plot(Fstretch.rmc,xlab = "Fascicle stretch [mm]",ylab = "Peak fascicle force [N]",overall =F, palette= myPal, lwd=3, lty=2, cex = 2, cex.axis = 1.2, cex.lab = 1.5, las=1, bty="L")
minor.tick(2,2,0.75)

#if you want to plot text of the rmcorr results
#text(34, 2, adj=1, bquote(italic(r[rm])~=Fstretch.rmc$rm), cex=1.5)
#text(34, 0, adj=1, bquote(italic(p)~"=0.34"), cex=1.5)

#2nd rmcorr - Fascicle stretch - rfe effect
matdata <- data.frame(cbind(my_data$Subj, my_data$Fstretch,my_data$rFE))
FasStretch.rmc <- rmcorr(my_data$Subj, my_data$Fstretch,my_data$rFE, matdata)
print("Fascicle stretch - rFE RMCORR")
print(FasStretch.rmc)
print("Adjusted p-value: ")
print(FasStretch.rmc $p * num_test) #print adjusted p value

plot(FasStretch.rmc,xlab = "Fascicle stretch [mm]",ylab = labelY,overall =F, palette= myPal, lwd=3, lty=2, cex = 2, cex.axis = 1.2, cex.lab = 1.5, las=1, bty="L")
minor.tick(2,2,0.75)

#3rd rmcorr - Fascicle peak force - rFE effect
matdata <- data.frame(cbind(my_data$Subj, my_data$Fas_Force,my_data$rFE))
FasForce.rmc <- rmcorr(my_data$Subj, my_data$Fas_Force,my_data$rFE, matdata)
print("Peak fascicle force - rFE RMCORR")
print(FasForce.rmc)
print("Adjusted p-value: ")
print(FasForce.rmc$p * num_test) #print adjusted p value

plot(FasForce.rmc,xlab = "Peak fascicle force [N]",ylab = labelY,overall =F, palette= myPal, lwd=3, lty=2, cex = 2, cex.axis = 1.2, cex.lab = 1.5, las=1, bty="L")
minor.tick(2,2,0.75)
