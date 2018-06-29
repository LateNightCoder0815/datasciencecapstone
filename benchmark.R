source('predict.R')
library(readtext)

## Read corpus
corpus <- corpus(readtext('data/testset.txt'))

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

ngrams <- tokens_ngrams(myTokens, n = 4, concatenator = " ")

correct <- 0
wrong <- 0
ngrams <- as.list(ngrams)

start_time <- Sys.time()
for (test in ngrams[[1]]) {
  test <- strsplit(test," ")[[1]]
  pred <- predictNGRAM(paste(test[1:3],collapse =" "))
  
  if (pred == test[4]){
    correct <- correct + 1
  }else{
    wrong <- wrong +1
  }
} 
end_time <- Sys.time()


print('Time per prediction:')
print(unclass(end_time - start_time) / length(ngrams[[1]]))
print('Accuracy:')
print(correct / (correct + wrong))
