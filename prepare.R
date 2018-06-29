library(LaF)
library(data.table)
library(quanteda)
## Problem to install readtext library was related to poppler-dev package. Cran version
## did not work. Needed to install from github the latest version.
library(readtext)
library(ggplot2)
library(dplyr)
library(tidyr)
library(splitstackshape)
## Set threads / there seems to be a bug in quanteda not catching this
quanteda_options(threads = 2)

## Download the dataset and unpack it
downloadUnzip <- function(){
  fileName <- 'swiftkey.zip'
  
  ## Defined folder in zip file
  folderName <- 'final'
  
  ## Download dataset if not exist
  if (!file.exists(fileName)){
    download.file('https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip',
                  fileName)
  }
  
  ## Unzip files if not done previously
  if (!file.exists(folderName)){
    unzip(fileName)
  }
}


# This function draws a random sample from the file
# We use p% of every file and save it to disk
createSample <- function(p){
  set.seed(0815)
  mySampleFile<- file('data/sample.txt',"w") 
  numLines <- determine_nlines('final/en_US/en_US.twitter.txt')
  writeLines(sample_lines('final/en_US/en_US.twitter.txt', n=numLines*p, numLines),
             con = mySampleFile)
  numLines <- determine_nlines('final/en_US/en_US.blogs.txt')
  writeLines(sample_lines('final/en_US/en_US.blogs.txt', n=numLines*p, numLines),
             con = mySampleFile)
  numLines <- determine_nlines('final/en_US/en_US.news.txt')
  writeLines(sample_lines('final/en_US/en_US.news.txt', n=numLines*p, numLines),
             con = mySampleFile)
  close(mySampleFile)
}

createTestSet <- function(){
  ## Read the sample file
  mySampleFile <- file('data/sample.txt',"r")
  lines <- readLines(mySampleFile)
  close(mySampleFile)
  
  ## We use 1% test file size as the sample is really large
  testSize <- floor(length(lines)*0.01)

  ## Create train and test set
  testSet <- lines[1:testSize]
  trainSet <- lines[testSize:length(lines)]
  
  ## Save sets to file
  testFile <- file('data/testset.txt',"w") 
  trainFile <- file('data/sample.txt',"w")
  writeLines(testSet, con = testFile)
  writeLines(trainSet, con = trainFile)
  close(testFile)
  close(trainFile)
}

## This function creates tokens from the sample, which is cleaned and filtered initially
createTokens <- function(){
  ## Read corpus
  corpus <- corpus(readtext('data/sample.txt'))
  
  ## Clean the data for punctuation, numbers, symbols, twitter tafs, urls
  myTokens <- tokens(corpus, what='word', remove_punct = TRUE, 
                     remove_numbers = TRUE, remove_symbols = TRUE, 
                     remove_twitter = TRUE, remove_url = TRUE)
  
  rm(corpus)
  
  ## Remove common stop words and lower case tokens
  myTokens <- tokens_remove(myTokens, stopwords('english'))
  myTokens <- tokens_tolower(myTokens)
  
  ## Clean for bad words we do not want to predict
  ## The list is from google hosted in the following github repo
  ## Source: https://github.com/RobertJGabriel/Google-profanity-words
  badWords <- read.table('bad_words.txt')
  badWords <- as.character(badWords$V1)
  badWords <- tolower(badWords)
  ## Remove from token set
  myTokens <- tokens_remove(myTokens, badWords)
  
  save(myTokens,file='data/myTokens.RData')
  rm(myTokens)
}

## This function builds the 2grams and formats the frequency table
build2grams <- function(){
  load(file='data/myTokens.RData')
  ## Build 2-grams
  myDFM2 <- dfm(myTokens, ngrams = 2, concatenator = ' ')
  
  ## Get frequencies
  freq2 <- select(textstat_frequency(myDFM2),c('feature','frequency'))
  rm(myDFM2)
  
  ## We want to have a prediction based on the previous word
  ## Split into accessible columns
  freq2 <- cSplit(freq2, "feature", " ")
  names(freq2) <- c("frequency","feature","predict")
  
  ## Save frequency table
  save(freq2,file='data/freq2.RData')
  rm(freq2)
}

## Data compression for our small prediction app
compress2grams <- function(){
  load(file='data/freq2.RData')
  ## We only need to keep the prediction with the highest frequency (saves a lot of space)
  freq2 <- freq2 %>% group_by(feature) %>% top_n(1,frequency)

  ## We obtain a grouped df which we want to convert back
  freq2 <- as.data.frame(freq2)
  
  ## We do not need the frquency anymore
  freq2 <- select(freq2,c('feature','predict'))
  
  ## As the elements are unique we can save space by storing as characters instead of factors
  freq2$predict <- as.character(freq2$predict)
  freq2$feature <- as.character(freq2$feature)
  
  ## Save for our prediction model
  save(freq2,file='data/2gram.RData')
  
  rm(freq2)
}


## This function builds the 3grams and formats the frequency table
build3grams <- function(){
  load(file='data/myTokens.RData')
  ## Build 3-grams
  myDFM3 <- dfm(myTokens, ngrams = 3, concatenator = ' ')
  
  ## Get frequencies
  freq3 <- select(textstat_frequency(myDFM3),c('feature','frequency'))
  rm(myDFM3)
  
  ## We want to have a prediction based on the previous words
  freq3 <- cSplit(freq3, "feature", " ")
  
  ## Merge features again
  freq3 <- unite(freq3,feature, c('feature_1','feature_2'),sep=' ')
  names(freq3) <- c("frequency","feature","predict")
  
  ## Save frequency table
  save(freq3,file='data/freq3.RData')
  rm(freq3)
}

## Data compression for our small prediction app
compress3grams <- function(){
  load(file='data/freq3.RData')
  
  ## Only consider words occured more than once // saves a lot of space
  freq3 <- freq3[freq3$frequency>1,]
  
  ## We only need to keep the prediction with the highest frequency (saves a lot of space / compute power)
  freq3 <- freq3 %>% group_by(feature) %>% top_n(1,frequency)
  
  ## We obtain a grouped df which we want to convert back
  freq3 <- as.data.frame(freq3)
  
  ## We do not need the frequency anymore
  freq3 <- select(freq3,c('feature','predict'))
  
  ## Save for our prediction model
  save(freq3,file='data/3gram.RData')
  
  rm(freq3)
}

## This function builds the 4grams and formats the frequency table
build4grams <- function(){
  load(file='data/myTokens.RData')
  
  ## Build 4-grams
  myDFM4 <- dfm(myTokens, ngrams = 4, concatenator = ' ')
  
  ## Get frequencies
  freq4 <- select(textstat_frequency(myDFM4),c('feature','frequency'))
  rm(myDFM4)
  
  ## We want to have a prediction based on the previous words
  ## Tidyr very unreliable with large datasets / cSplit turned out to be a lot better ...
  freq4 <- cSplit(freq4, "feature", " ")
  
  ## Merge features again
  freq4 <- unite(freq4,feature, c('feature_1','feature_2','feature_3'),sep=' ')
  names(freq4) <- c("frequency","feature","predict")
  
  ## Save frequency table
  save(freq4,file='data/freq4.RData')
  rm(freq4)
}

## Data compression for our small prediction app
compress4grams <- function(){
  load(file='data/freq4.RData')
  
  ## Only consider words occured more than once // saves a lot of space
  freq4 <- freq4[freq4$frequency>1,]
  
  ## We only need to keep the prediction with the highest frequency (saves a lot of space)
  freq4 <- freq4 %>% group_by(feature) %>% top_n(1,frequency)
  
  ## We obtain a grouped df which we want to convert back
  freq4 <- as.data.frame(freq4)
  
  ## We do not need the frequency anymore
  freq4 <- select(freq4,c('feature','predict'))
  
  ## Save for our prediction model
  save(freq4,file='data/4gram.RData')
  
  rm(freq4)
  
}

createDataTables <- function(){
  load('data/2gram.RData')
  # Convert to data table / much faster
  freq2 <- as.data.table(freq2)
  # Set the index
  setkey(freq2,feature)
  # Write file to disc
  fwrite(freq2,'data/2gram.DT')
  rm(freq2)
  
  
  load('data/3gram.RData')
  # Convert to data table / much faster
  freq3 <- as.data.table(freq3)
  # Set the index
  setkey(freq3,feature)
  # Write file to disc
  fwrite(freq3,'data/3gram.DT')
  rm(freq3)
  
  
  load('data/4gram.RData')
  # Convert to data table / much faster
  freq4 <- as.data.table(freq4)
  # Set the index
  setkey(freq4,feature)
  # Write file to disc
  fwrite(freq4,'data/4gram.DT')
  rm(freq4)
}
  
### MAIN
### function calls
## We cranked the sample percentage up until the quanteda package killed the R session on my machine ...
## The steps can be run subsequentially in order to be able to restart if something strange happened
## Overall R does not seem to be the ideal environment for such large processing tasks
## Trying to have everything in memory and single threading are very tough limitations

downloadUnzip()
createSample(0.3)
createTestSet()
createTokens()
build2grams()
compress2grams()
build3grams()
compress3grams()
build4grams()
compress4grams()
createDataTables()
