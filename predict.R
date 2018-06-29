library(quanteda)
library(data.table)

# Load varaibles into memory
freq2 <- fread('data/2gram.DT')
freq3 <- fread('data/3gram.DT')
freq4 <- fread('data/4gram.DT')

# Create index
setkey(freq2,feature)
setkey(freq3,feature)
setkey(freq4,feature)

predictNGRAM <- function(predictInput){
  ## Read the inout
  corpus <- corpus(predictInput)
  
  ## Use same cleaning as in the preparation
  myTokens <- tokens(corpus, what='word', remove_punct = TRUE, 
                     remove_numbers = TRUE, remove_symbols = TRUE, 
                     remove_twitter = TRUE, remove_url = TRUE)
  
  myTokens <- tokens_remove(myTokens, stopwords('english'))
  myTokens <- tokens_tolower(myTokens)
  rm(corpus)
  
  # Only need one document
  myTokens <- myTokens$text1
  
  # Determine token length
  myTokensLength <- length(myTokens)
  
  result <- NA
  
  ## 4-gram prediction
  if (myTokensLength > 2){
    searchString <- paste(tail(myTokens,3), collapse=' ')
    result <- freq4[searchString,]$predict[1]
  }
  
  ## If not successful 3-grams
  if ((myTokensLength > 1) & (is.na(result))){
    searchString <- paste(tail(myTokens,2), collapse=' ')
    result <- freq3[searchString,]$predict[1]
  }
  
  ## Still not successful 2-grams
  if ((myTokensLength > 0) & (is.na(result))){
    searchString <- tail(myTokens,1)
    result <- freq2[searchString,]$predict[1]
  }
  
  ## Still no result -> return most frequent word according to our analysis
  if (is.na(result)){
    result <- 'said'
  }
  
  ## In case of draw in frequency take the first one
  result
}


