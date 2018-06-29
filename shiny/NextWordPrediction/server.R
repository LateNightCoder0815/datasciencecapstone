library(shiny)

source('predict.R')

shinyServer(function(input, output) {
   
  output$prediction <- renderText({
    ## Return prediction    
    predictNGRAM(input$predictInput)
    
  })
  
})
