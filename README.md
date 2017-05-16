# Script files
**run_analysis.R** is the only file needed to:

1. Download the data
2. Process the data
3. Create the tidy data set.

There two other files included per assignment objectives:
1. CodeBook.md: Meets assignment objective #3: GitHub contains a code book that modifies and updates the available codebooks with the data to indicate all the variables and summaries calculated, along with units, and any other relevant information.
2. tidyDataSet.csv: Meets assignment objective #5 (from the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.)

# Execution steps
This section details how the code accomplishes the objectives of the assignment.

The code breaks down the work required to accomplish the objectives of the assignment into 8 primary steps.

1. Download the data
2. Read the test and training data
3. Merge the test and training data together to create one data set (assignment objective #1)
4. Extract only the measurements on the mean and standard deviation for each measurement (assignment objective #2)
5. Clean up column names and appropriately label the data set with descriptive variable names (assignment objective #4)
6. Create a second, independent tidy data set with the average of each variable for each activity and each subject (assignment objective #5).
7. Write the tidy data to a .csv

The steps above are each accomplished with 1 or more primary functions. Each primary function may use 1 or more helper functions.

The sections below detail the code that accomplishes each step.

# Step 1: Download the data
This is accomplished with function downloadData().

* Uses download.file() to download the zip file containing the data
* Uses unzip() to extract the data files necessary for the assignment objectives

Output: A directory "data" created in the users working directory, containing the data files necessary for the project objectives

# Step 2: Read the test and training data
Reads the test and training data into their own data frames, testActivityData and trainingActivityData.
There are 2 functions for this:

1. getTestActivityData()
2. getTrainingActivityData()

Each function is the same, the only difference is the files used for each step. Here is a summary:

1. Read the activity data, either "./data/X_test.txt" for the test data set, or "./data/X_train.txt" for the training data set. This is done via a helper function which wraps read.table(). The data is read into a data frame, either testData or trainingData

2. Set the column headers on the data frame created in step 1 by reading the "./data/features.txt" file
+ Call helper function getColumnNames() which uses read.table() to read the second colume of data from "./data/features.txt"
+ Use make.names() to make each column name unique because there are some duplicated values in "./data/features.txt"

3. Calls helper function addActivityLabels(). This meets objective #4 ("Uses descriptive activity names to name the activities in the data set")
+ Uses read.table() to read the data from "./data/activity_labels.txt" into a dataframe called activityLabels with 2 columns: activityId and activityDescription
+ Uses read.table to read either "./data/y_test.txt" for the test data, or "./data/y_train.txt" for the training data - to read the activity id's. Creates a data frame, activities, with a single column, activityId
+ Uses left_join() from dplyr to join activities and activityLabels into a single data frame, activities. The 2 dataframes are joined on activityID.
+ Uses dplyr select() to select just the friendly activity description in the activityDescription column
+Uses dplyr bind_cols() to join the data frames containing the activity data and the data frame containing the friendly activity description

Output: 2 data frames (testActivityData and trainingActivityData) with the training and test data - including a column of descriptive activity names and with unique column names. 

# Step 3: Merge the test and training data together to create one data set (assignment objective #1)

This step merges the 2 data frames created in step 2.

Output: a single data frame called combinedData which contains both the training and test data.

1. Uses dplyr bind_rows() to bind the testActivityData and trainingActivityData data frames into a single data frame called combined data.

# Step 4: Extract only the measurements on the mean and standard deviation for each measurement (assignment objective #2)

Uses a function removeExtraneousColumns() which:

1. Creates a character vector containing the names of columns to keep called initialColumnNames
  + Reads in the values ("subject","activityDescription","dataSet") into meanColumnNames
  + Uses grep() to read in any values containing "std" or "mean" into standardDeviationColumnNames
  + Combines initialColumnNames, meanColumnNames and standardDeviationColumnNames into a vector called columnsToKeep
2. Removes any ny columns containging "angle" because as per line 49 of 'features_info.txt' these measures actually measure the angle between to vectors as opposed to being a measure of mean or standard deviation
3. Remove any columns containing "meanFreq" because as per line 45 of 'features_info.txt' these are actually "weighted average of the frequency components to obtain a mean frequency" and not a meausre of the mean for a single measurement as per assignment instructions
4. Use dplyr select() to keep only the columns in the columnsToKeep vector from the activityData data frame

Output: modifies the dataframe named combinedData, with only the measures measurements on the mean and standard deviation for each measurement (assignment objective #2)

# Step 5: Clean up column names and appropriately label the data set with descriptive variable names (assignment objective #4)
Calls a function called cleanUpColumnNames() which:
1. Replace repeated '.' characters in the column names with a single '.' character 
2. Removes trailing '.' periods in column names

Output: a modified combinedData data frame with no trailing or repeated '.' characters in the column headers

# Step 6: Create a second, independent tidy data set with the average of each variable for each activity and each subject (assignment objective #5.)
Calls a function createAverageTidyDataSet() which

1. Uses melt() from the reshape2 library to take the data from the combinedData data frame and make it "narrow" - with one row per measure - for each subject and activity description combination

2. Calls a helper functions getTidyDataBySubject() and getTidyDataByActivity() which
+cast the meletd data from step 1 into 1 row per each subject + variable combination - calcuating the mean for each variable
+add a column called "grouped by" to indicate which attribute from source the data is grouped by - either subject or activityDescription
+For subject data only: convert subject column from integer to character so it binds with the tidy data by activity data frame, where subject is a factor
+Calls a helper function moveColumnToBeginningOfDataFrame() which moves the new "groupedBy" column to the first column in the data frame. NOTE: adapted from code in this thread: http://stackoverflow.com/a/3370115/7416441 
+Renames the subject column to groupedByValue to indicate what subject or activityDescription each row relates to

Output: a data frame, tidyData, which is a second, independent tidy data set with the average of each variable for each activity and each subject. (assignment objective #5)

# Step 7: Write the tidy data to a .csv
Calls write.csv() to write the tidyData to a .csv file (assignment objective #5)

