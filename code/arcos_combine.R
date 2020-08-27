master <- data.frame(ZIPCODE=character(),
                     DRUGCODE=character(),
                     Q1=double(),
                     Q2=double(),
                     Q3=double(),
                     Q4=double(),
                     YEAR=integer(),
                     stringsAsFactors=FALSE)

for (year in 2000:2019) {
    print(year)
    tmp <- read.csv(paste("data/raw/_arcos_csv/prescriptions_",year,".csv", sep=""))
    tmp$YEAR <- year
    master <- rbind(master, tmp)
}

master <- master[,c(7,1,2,3,4,5,6)]
write.csv(master, "data/raw/prescriptions.csv",row.names=FALSE,quote=FALSE)
