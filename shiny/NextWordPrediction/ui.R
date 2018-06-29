library(shiny)

shinyUI(fluidPage(
  
  # Load custom style sheet
  includeCSS("style.css"),
  
  # Application title
  headerPanel("Data Science Capstone Project: Next Word Prediction",
              windowTitle = 'Next Word Prediction'),
  
  br(),br(),br(),br(),br(),br(),
  # Sidebar with explanations 
  sidebarLayout(
    sidebarPanel(
       h2('User guide'),
       p("The usage of the app is straight forward. Please
           just enter an English sentence in the input box on
           the right. The system will automatically predict
           the next word. We ignore stop and profanity
           words. If no word can be predicted (e.g. 
           empty input box, only stop or unknown words)
           the most frequent word according to our analysis 
           'said' is given.")
    ),
    
    # Show a input box and the prediction
    mainPanel(
      h4('Enter your text here [English version]:'),
      textInput('predictInput',label='', value='Hi '),
      br(),
      h4('Predicted Output:'),
      br(),
      textOutput('prediction'),
      br(),br(),
      h2('More information'),
      p("More information can be found through the following links:"),
      tags$ul(
        tags$li(a('Slide deck with app presentation', href='http://rpubs.com/LateNIghtCoder0815/slidedeck')), 
        tags$li(a('Github repository containing the code', href='https://github.com/LateNightCoder0815/datasciencecapstone'))
      )
    )
  )
))
