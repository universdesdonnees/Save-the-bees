library(shiny)
library(plotly)
library(tidyverse)

bees_data <- read.csv("data/save_the_bees.csv") %>% 
  mutate(year_quarter = paste0(year, "-", quarter))

ui <- fluidPage(
  titlePanel("Save the Bees"),
  navlistPanel(
    tabPanel("Data Table",
             selectInput("year", "Year", choices = unique(bees_data$year)),
             selectInput("quarter", "Quarter", choices = unique(bees_data$quarter)),
             checkboxInput("show_all", "Show All Rows", FALSE),
             tableOutput("table")
    ),
    tabPanel("Graphs",
             selectInput("stateplot", "State", choices = unique(bees_data$state)),
             plotOutput("pesticide_disease_graph"),
             plotOutput("bee_tracking_graph")
    ),
    tabPanel("Map",
             selectInput("year_plot", "Year", choices = unique(bees_data$year)),
             plotlyOutput("map")
    )
  )
)

server <- function(input, output) {
  
  output$table <- renderTable({
    if(input$show_all) {
      bees_data %>% 
        filter( year == input$year, quarter == input$quarter) %>%
        arrange(state)
    }else{
      bees_data %>% 
        filter(year == input$year, quarter == input$quarter) %>%
        arrange(state) %>% 
        head(3)
    }
  })
  
  filtered_data <- reactive({
    bees_data %>% 
      filter(state == input$stateplot)
  })
  
  output$pesticide_disease_graph <- renderPlot({
    filtered_data() %>% 
      select(state,year_quarter,varroa_mites,other_pests_and_parasites,
             pesticides,diseases,other,unknown ) %>% 
      gather(key = "maladie", value = "pourcentage", -c(state, year_quarter)) %>% 
      ggplot(aes(x = year_quarter, y=pourcentage, color=maladie, group=maladie)) +
      geom_line() +
      labs(title = paste("Pests and Diseases graph in", input$stateplot), 
           x="",y = "% of colonies affected") +
      theme_classic() +
      theme(plot.title = element_text(hjust = 0.5),
            axis.text.x = element_text(angle = 75, vjust = 0.5),
            axis.line = element_line(color = "black"),
            legend.title = element_blank())+
      scale_color_manual(values = c("#afeeee","#d8bfd8","#fa8072", 
                                    "#daa520","#808080", "#93be93"))
  })
  
  output$bee_tracking_graph <- renderPlot({
    filtered_data() %>% 
      select(num_colonies,lost_colonies,added_colonies,state,year_quarter) %>%
      gather(key = "nombre", value = "value", -c(state, year_quarter)) %>% 
      ggplot(aes(x=year_quarter,y= value,color=nombre,group=nombre)) +
      geom_line() +
      labs(title = paste("Colony Tracker in", input$stateplot), 
           x = "Time (Year-Quarter)",y = "Number of Colonies") +
      theme_minimal() + 
      theme(plot.title = element_text(hjust = 0.5),
            axis.text.x = element_text(angle = 75, vjust = 0.5),
            axis.line = element_line(color = "black"),
            legend.title = element_blank())+
      scale_color_manual(values = c("#b4efef","#fb968a","#a4c9a4"))
  })
  
  output$map <- renderPlotly({
    bees_data %>% filter(year==input$year_plot)%>%
      plot_ly() %>%
      add_trace(
        type = "choropleth",
        locations = ~state_code,
        locationmode = "USA-states",
        z = ~num_colonies,
        colorscale = "num_colonies",
        color = ~num_colonies
      ) %>%
      layout(
        geo = list(scope = "usa")
      )
  })
}

shinyApp(ui = ui, server = server)
