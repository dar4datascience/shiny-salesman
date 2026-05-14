library(shiny)
library(waiter)
library(bslib)
library(thematic)
library(bsicons)

if (!exists("all_cities"))
  all_cities = readRDS("data/cities.rds")
if (!exists("usa_cities"))
  usa_cities = readRDS("data/usa_cities.rds")

library(ragg)
options(shiny.useragg = TRUE)

thematic_shiny(font = "auto")

ui_theme <- bs_theme(
  version = 5,
  bootswatch = "sketchy",
  bg = "#008080",
  fg = "#000",
  base_font = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
)

page_sidebar(
  title = tags$span(bsicons::bs_icon("globe-americas"), "Shiny T-Salesman"),
  theme = ui_theme,
  useWaiter(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom_styles.css")
  ),
  sidebar = sidebar(
    input_dark_mode(),
    hr(),
    checkboxInput("label_cities", "Label cities on map?", FALSE),
    selectInput("map_name", "Map", c("World", "USA"), "World"),
    selectizeInput(
      "cities",
      "Cities to visit",
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
    ),
    actionButton("set_random_cities", "Set Randomly", icon = bs_icon("shuffle")),
    hr(),
    h5("Simulated Annealing Parameters"),
    numericInput("s_curve_amplitude", "S-curve Amplitude", 4000, min = 0, max = 10000000),
    numericInput("s_curve_center", "S-curve Center", 0, min = -1000000, max = 1000000),
    numericInput("s_curve_width", "S-curve Width", 3000, min = 1, max = 1000000),
    numericInput("total_iterations", "Iterations", 25000, min = 0, max = 1000000),
    numericInput("plot_every_iterations", "Draw Every N Iterations", 1000, min = 1, max = 1000000),
    hr(),
    actionButton("go_button", "SOLVE", class = "btn-info btn-lg w-100"),
    actionButton("set_random_cities_2", "Set Cities Randomly", icon = bs_icon("arrow-repeat"), class = "btn-secondary w-100 mt-2"),
    tags$div(
      class = "mt-3 text-center",
      tags$a(
        href = "https://github.com/dar4datascience/shiny-salesman",
        target = "_blank",
        bsicons::bs_icon("github")
      )
    )
  ),
  card(
    full_screen = TRUE,
    card_header("Tour Map"),
    plotOutput("map", height = "550px")
  ),
  layout_columns(
    card(
      full_screen = TRUE,
      card_header("Annealing Schedule"),
      plotOutput("annealing_schedule", height = "260px")
    ),
    card(
      full_screen = TRUE,
      card_header("Evolution of Current Tour Distance"),
      plotOutput("distance_results", height = "260px")
    )
  ),
  tags$div(
    class = "text-center mt-2",
    tags$a(
      href = "https://toddwschneider.com/posts/traveling-salesman-with-simulated-annealing-r-and-shiny/",
      "Traveling Salesman with Simulated Annealing, Shiny, and R",
      target = "_blank"
    )
  )
)
