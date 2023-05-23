library(shiny)
library(waiter)
library(bslib)
library(thematic)

if (!exists("all_cities"))
  all_cities = readRDS("data/cities.rds")
if (!exists("usa_cities"))
  usa_cities = readRDS("data/usa_cities.rds")
# In order for auto/custom fonts to work properly, you'll want
# either the ragg (or showtext) package installed
library(ragg)
ui_theme <- bs_theme(
  bg = "#008080",
  font_scale = 1.2,
  bootswatch = "sketchy",
  fg = "#000"
)
# If you want `{ragg}` to handle the font rendering in a Shiny app
options(shiny.useragg = TRUE)

# Call thematic_shiny() prior to launching the app, to change
# R plot theming defaults for all the plots generated in the app
thematic_shiny(font = "auto")

shinyUI(
  fluidPage(
    title = "Shiny T-Salesman",
    header = TRUE,
    # Set header argument to TRUE
    useWaiter(),
    theme = ui_theme,
    tags$style(HTML("
    .rounded-logo {
      border-radius: 50%;
      width: 30px;
      height: 30px;
      margin-right: 10px;
    }
    .app-title {
      display: flex;
      align-items: center;
    }
    .navbar {
      margin-bottom: 20px;
      background-color: #f8f9fa;
    }
    .navbar-nav {
      display: flex;
      align-items: center;
      padding: 0;
      margin: 0;
    }
    .navbar-nav li {
      list-style-type: none;
      margin-right: 10px;
    }
    .navbar-nav li a {
      text-decoration: none;
      color: #333333;
      padding: 10px;
      border-radius: 5px;
    }
    .navbar-nav li.nav-title a {
      font-weight: bold;
      font-size: 18px;
    }
    .navbar-nav li.nav-title a:hover {
      background-color: transparent;
    }
    .navbar-nav li a:hover {
      background-color: #e9ecef;
    }
    .navbar-nav.ml-auto {
      margin-left: auto;
    }
    .navbar-github-icon {
      display: flex;
      align-items: center;
      
    }
  ")),
    #useHostess(),
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom_styles.css")
    ),
    div(
      class = "navbar",
      div(
        class = "navbar-nav",
        div(
          class = "rounded-logo",
          img(
            src = "https://thumbs.dreamstime.com/z/traveling-salesman-23482210.jpg",
            width = "100%",
            height = "100%",
            style = "border-radius: 50%"
          )
        ),
        tags$li(class = "nav-item nav-title",
                "Shiny salesman"),
        tags$li(class = "nav-item",
                tags$a("Random Travel",
                       icon("plane"),
                       href = "#")),
        tags$li(class = "nav-item",
                tags$a("Select your cities!",
                       icon("map-pin"),
                       href = "#")),
        
        div(class = "navbar-github-icon",
            tags$a(href = "https://github.com/dar4datascience/shiny-salesman",
                   class = "nav-link",
                   tags$i(class = "fab fa-github")
            )
        )
      )
    ),
    div(class = "app-title",
        
        h1("Traveling Salesman"))
    ,
    fluidRow(column(
      width = 12,
      checkboxInput("label_cities", "Label cities on map?", FALSE)
    )),
    fluidRow(column(width = 12,
                    tags$h2(
                      tags$a(
                        href = "https://toddwschneider.com/posts/traveling-salesman-with-simulated-annealing-r-and-shiny/",
                        "Traveling Salesman with Simulated Annealing, Shiny, and R",
                        target = "_blank"
                      )
                    ))),
    fluidRow(column(
      width = 12,
      plotOutput("map", height = "550px")
    )),
    fluidRow(
      column(width = 5,
             tags$ol(
               tags$li("Customize the list of cities, based on the world or US map"),
               tags$li("Adjust simulated annealing parameters to taste"),
               tags$li("Click the 'solve' button!")
             )),
      column(
        width = 3,
        tags$button("SOLVE", id = "go_button", class = "btn btn-info btn-large action-button shiny-bound-input")
        
      ),
      column(
        width = 3,
        HTML(
          "<button id='set_random_cities_2' class='btn btn-large action-button shiny-bound-input'>
              <i class='fa fa-refresh'></i>
              Set Cities Randomly
            </button>"
        )
      )
    ),
    
    hr(),
    
    fluidRow(
      column(
        5,
        h4("Choose a map and which cities to tour"),
        selectInput("map_name", NA, c("World", "USA"), "World", width = "100px"),
        p(
          "Type below to select individual cities, or",
          actionButton("set_random_cities", "set randomly", icon = icon("refresh"))
        ),
        selectizeInput(
          "cities",
          NA,
          all_cities$full.name,
          multiple = TRUE,
          width = "100%",
          options = list(
            maxItems = 30,
            maxOptions = 100,
            placeholder = "Start typing to select some cities...",
            selectOnTab = TRUE,
            openOnFocus = FALSE,
            hideSelected = TRUE
          )
        )
      ),
      
      column(
        2,
        h4("Simulated Annealing Parameters"),
        inputPanel(
          numericInput(
            "s_curve_amplitude",
            "S-curve Amplitude",
            4000,
            min = 0,
            max = 10000000
          ),
          numericInput(
            "s_curve_center",
            "S-curve Center",
            0,
            min = -1000000,
            max = 1000000
          ),
          numericInput(
            "s_curve_width",
            "S-curve Width",
            3000,
            min = 1,
            max = 1000000
          ),
          numericInput(
            "total_iterations",
            "Number of Iterations to Run",
            25000,
            min = 0,
            max = 1000000
          ),
          numericInput(
            "plot_every_iterations",
            "Draw Map Every N Iterations",
            1000,
            min = 1,
            max = 1000000
          )
        ),
        class = "numeric-inputs"
      ),
      
      column(
        5,
        plotOutput("annealing_schedule", height = "260px"),
        plotOutput("distance_results", height = "260px")
      )
    )
  )
)
