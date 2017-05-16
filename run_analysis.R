library(dplyr)
library(reshape2)

#download and extract data
downloadData<-function() {    
    fileURL<-"https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
    filesToExtract<-c("UCI HAR Dataset/activity_labels.txt","UCI HAR Dataset/features.txt","UCI HAR Dataset/test/subject_test.txt","UCI HAR Dataset/train/subject_train.txt","UCI HAR Dataset/test/X_test.txt","UCI HAR Dataset/train/X_train.txt","UCI HAR Dataset/test/y_test.txt","UCI HAR Dataset/train/y_train.txt")
    download.file(fileURL,"data.zip", mode="wb")
    unzip("data.zip",files=filesToExtract,exdir="./data",junkpaths=TRUE)    
}

#read column names
getColumnNames <-function(file) {
    read.table(file)[[2]]
}
#read data set
readDataSet <-function (file) {
    read.table(file)
}

addActivityLabels <-function (activityLabelsFile, activitiesDataFile, activityData) {
    #read activity labels file into dataframe    
    #this will be used to map activity Id's (numbers) to "descriptive variable names" as per project requirement #4
    activityLabels<-read.table(activityLabelsFile,col.names=c("activityId","activityDescription"))
    
    #read in activity id's for this data set
    activities<-read.table(activitiesDataFile,col.names=c("activityId"))
    
    #use join to add friendly activity description - joins by matching column name 'activityId'
    activities<-left_join(activities,activityLabels)
    
    #select just the friendly activity name
    activities<-select(activities,activityDescription)
    
    #bind activities to data
    bind_cols(activities,activityData)    
}

addSubjectLabels <-function (subjectLabelsFile,activityData) {
    #read subjects
    subjects<-read.table(subjectLabelsFile,col.names=c("subject"))
    
    #bind with activity data
    bind_cols(subjects,activityData)
}

getTestActivityData <-function () {
    #read data set
    testData<-readDataSet("./data/X_test.txt")
    
    #add column headers for data
    #Using make.names to change names for duplicated features present in features.txt
    names(testData)<-make.names(getColumnNames("./data/features.txt"), unique=TRUE, allow_=TRUE)    
    
    # 3. Uses descriptive activity names to name the activities in the data set
    #add activity labels column
    testData<-addActivityLabels("./data/activity_labels.txt","./data/y_test.txt",testData)
    
    #add test subject labels
    testData<-addSubjectLabels("./data/subject_test.txt",testData)   
}

getTrainingActivityData <-function () {
    #read data set
    trainingData<-readDataSet("./data/X_train.txt")
    
    #add column headers for data
    #Using make.names to change names for duplicated features present in features.txt
    names(trainingData)<-make.names(getColumnNames("./data/features.txt"), unique=TRUE, allow_=TRUE)
    
    # 3. Uses descriptive activity names to name the activities in the data set
    #add activity labels column    
    trainingData<-addActivityLabels("./data/activity_labels.txt","./data/y_train.txt",trainingData)
    
    #add test subject labels
    trainingData<-addSubjectLabels("./data/subject_train.txt",trainingData)
}

removeExtraneousColumns <-function(activityData) {
    #specify inital column names to keep
    initialColumnNames<-c("subject","activityDescription","dataSet")
    
    #get column names for mean
    meanColumnNames<-grep("mean",names(activityData),ignore.case = TRUE,value=TRUE)
    
    #get column names for standard deviation
    standardDeviationColumnNames<-grep("std",names(activityData),ignore.case = TRUE,value=TRUE)
    
    #combine three vectors into single vector
    columnsToKeep<-c(initialColumnNames,meanColumnNames,standardDeviationColumnNames)
    
    #remove any columns containging "angle" because as per line 49 of 'features_info.txt'
    #these measures actually measure the angle between to vectors as opposed to being
    #a measure of mean or standard deviation
    columnsToKeep<-columnsToKeep[!grepl("angle", columnsToKeep)]
    
    #remove any columns containing "meanFreq" because as per line 45 of 'features_info.txt'
    #these are actually "weighted average of the frequency components to obtain a mean frequency"
    #and not a meausre of the mean for a single measurement as per assignment instructions
    columnsToKeep<-columnsToKeep[!grepl("meanFreq", columnsToKeep)]    
    
    #select only the columns in the combined columnsToKeep vector
    select(activityData,one_of(columnsToKeep))
}

cleanUpColumnNames <- function(activityData) {
    #replace repeated '.' characters with a single '.' character
    colnames(activityData)<-gsub("\\.{2,}",".",names(activityData))
         
    #remove trailing '.' periods in column names
    colnames(activityData)<-gsub("\\.\\z", "", names(activityData), perl=TRUE)
    activityData
}

addDescriptiveColumnNames <- function(activityData) {
    #get column names
    columnNames<-names(activityData)
    
    #if column name starts with "t" then replace with "Time"
    columnNames<-sub("\\At", "Time", columnNames, perl=TRUE)
    
    #if column name starts with "t" then replace with "Time"
    columnNames<-sub("\\Af", "Frequency", columnNames, perl=TRUE)
        
    #initiatize counter for iterating over columnNames
    i<-1
    
    for (columnName in columnNames) { 
                
        #for each name, if name contains "mean" - add prefix of "meanOf"
        if (grepl("mean",columnName,ignore.case = TRUE)) {
            columnNames[i] = paste0("meanOf",columnName)
        }
        #else if contains "std" - add prefix of "stdDevOf"
        else if (grepl("std",columnName,ignore.case = TRUE)) {
            columnNames[i] = paste0("stdDevOf",columnName)
        }
        i<-i+1        
    }
        
    #remove any occurrences of .mean
    columnNames<-sub("\\.mean", "", columnNames, perl=TRUE)
    
    #remove any occurrences of .std
    columnNames<-sub("\\.std", "", columnNames, perl=TRUE)
    
    #replace occurrences of '.X' with X
    columnNames<-sub("\\.X", "X", columnNames, perl=TRUE)
    
    #replace occurrences of '.Y' with Y
    columnNames<-sub("\\.Y", "Y", columnNames, perl=TRUE)
    
    #replace occurrences of '.Z' with Z
    columnNames<-sub("\\.Z", "Z", columnNames, perl=TRUE)
    
    #set final column names
    colnames(activityData)<-columnNames
    activityData
}

#adapted from http://stackoverflow.com/a/3370115/7416441
moveColumnToBeginningOfDataFrame <- function(df,columnName) {
    col_idx <- grep(columnName, names(df))
    df[, c(col_idx, (1:ncol(df))[-col_idx])]
}

getTidyDataBySubject <-function(meltedActivityData) {
    #cast the melted data to get mean for each variable by subject
    subjectMeans<-dcast(meltedActivityData,subject~variable,mean)
    
    #add a column called "grouped by" to indicate which attribute from source the data is grouped by
    #   before calculating the mean of each variable
    subjectMeans<-mutate(subjectMeans,groupedBy="subject")
    
    #convert subject column from integer to character so it binds with the
    # tidy data by activity data frame, where subject is a factor
    subjectMeans<-mutate(subjectMeans,subject=as.character(subject))
    
    #move new column to beginning of data frame
    subjectMeans<-moveColumnToBeginningOfDataFrame(subjectMeans,"groupedBy")
    
    #rename subject column to groupedByValue to indicate what subject each row relates to
    rename(subjectMeans, groupedByValue = subject)
    
}

getTidyDataByActivity <-function(meltedActivityData) {
    #cast the melted data to get mean for each variable by subject
    activityMeans<-dcast(meltedActivityData,activityDescription~variable,mean)
    
    #add a column called "grouped by" to indicate which attribute from source the data is grouped by
    #   before calculating the mean of each variable
    activityMeans<-mutate(activityMeans,groupedBy="activityDescription")
    
    #move new column to beginning of data frame
    activityMeans<-moveColumnToBeginningOfDataFrame(activityMeans,"groupedBy")
    
    #rename subject column to groupedByValue to indicate what activity description each row relates to
    rename(activityMeans, groupedByValue = activityDescription)
}

createAverageTidyDataSet <- function(activityData) {
    #melt the data - with subject and activityDescription being used as id values
    meltedActivityData<-melt(activityData,id=c("subject","activityDescription"))
    
    #get tidy data by subject
    tidySubjectData<-getTidyDataBySubject(meltedActivityData)
    
    #get tidy data by activity
    tidyActivityDescriptionData<-getTidyDataByActivity(meltedActivityData)

    #combined tidySubjectData and tidyActivityDescriptionData by row to finalize the tidy data set
    bind_rows(tidySubjectData,tidyActivityDescriptionData)
}

#dowload data
downloadData()

#read test data
testActivityData<- getTestActivityData()

#get training data
trainingActivityData<-getTrainingActivityData()

# 1. Merges the training and the test sets to create one data set
combinedData<-bind_rows(testActivityData,trainingActivityData)

# 2. Extracts only the measurements on the mean and standard deviation for each measurement.
combinedData<-removeExtraneousColumns(combinedData)

#clean up the column names to delete extraneous '.' characters
combinedData<-cleanUpColumnNames(combinedData)

# 4. Appropriately labels the data set with descriptive variable names.
combinedData<-addDescriptiveColumnNames(combinedData)

# 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.
tidyData<-createAverageTidyDataSet(combinedData)

#write the tidy data to .csv
write.csv(tidyData,file="tidyDataSet.csv",row.names=FALSE)