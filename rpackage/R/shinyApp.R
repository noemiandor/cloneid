# Script by Thomas Veith and Noemi Andor PhD
# This script serves as the back end to the CLONEID web portal.
# It provides interactive functionality for generating phylogenetic trees,
# visualizing genomic perspective data as heatmaps, and supporting seed/harvest functions.

# Load required libraries
library(shiny)          # Web application framework
library(DBI)            # Database interface
library(cloneid)        # CLONEID package for handling database and analysis
library(ggtree)         # Phylogenetic tree visualization
library(ggplot2)        # General plotting library
library(ComplexHeatmap) # For creating heatmaps
library(ape)            # For phylogenetic tree structures

# Helper function for executing database queries using CLONEID's connection
executeQuery <- function(query) {
  mydb <- cloneid::connect2DB()  # Establish a new database connection
  on.exit(dbDisconnect(mydb), add = TRUE)  # Ensure the connection is closed after query execution
  tryCatch({
    message("Executing query: ", query)  # Log the query being executed
    rs <- dbSendQuery(mydb, query)      # Send the query
    result <- dbFetch(rs)              # Fetch the results
    dbClearResult(rs)                  # Clear the query result set
    return(result)
  }, error = function(e) {
    message("Error executing query: ", e$message)  # Log the error message
    stop(e)  # Stop execution with the error message
  })
}

# Function to retrieve genomic perspective data
GenomePerspectiveView_Bulk <- function(id) {
  print(paste("Fetching genomic perspective data for ID:", id))
  
  # Construct and execute the query
  query <- paste0(
    "SELECT DISTINCT cloneID, parent 
     FROM Perspective 
     WHERE whichPerspective='GenomePerspective' 
     AND origin IN ('", id, "')"
  )
  origin <- executeQuery(query)
  
  # Check if the query returned any results
  if (nrow(origin) == 0) {
    stop("No genomic data available for the provided ID.")
  }
  
  # Identify the root cloneID and retrieve its profiles
  x <- origin$cloneID[is.na(origin$parent)]
  p <- getSubProfiles(cloneID_or_sampleName = x, whichP = "GenomePerspective")
  print("Done generating heatmap data")
  return(p)  # Return the heatmap matrix
}

# Function to construct a phylogenetic tree based on lineage
getPedigreeTree <- function(cellLine = NULL, id = NULL) {
  # Retrieve descendant data for a specific ID or cell line
  if (!is.null(id)) {
    kids <- findAllDescendandsOf(id)  # Get descendants for a specific ID
  } else if (!is.null(cellLine)) {
    query <- paste0("SELECT * FROM Passaging WHERE cellLine = '", cellLine, "'")
    kids <- executeQuery(query)  # Execute query for cell line
  } else {
    stop("Either 'cellLine' or 'id' must be provided.")  # Ensure at least one input is provided
  }
  
  # Check if any data was retrieved
  if (nrow(kids) == 0) {
    stop("No tree data available for the provided input.")
  }
  
  # Sort the data by date and passage for proper tree structure
  kids <- kids[order(kids$date, kids$passage), ]
  rownames(kids) <- kids$id  # Assign IDs as row names
  
  # Recursive function to gather descendants for tree construction
  .gatherDescendands <- function(kids, x) {
    ii <- grep(paste0("^", x, "$"), kids$passaged_from_id1, ignore.case = TRUE)
    if (length(ii) == 0) {
      return("")  # Return empty if no descendants
    }
    TREE_ <- "("
    for (i in ii) {
      y <- .gatherDescendands(kids, kids$id[i])  # Recurse for each descendant
      if (nchar(y) > 0) {
        y <- paste0(y, ":1,")
      }
      TREE_ <- paste0(TREE_, y, kids$id[i], ":1,")
    }
    TREE_ <- gsub(",$", ")", TREE_)  # Format tree string
    return(TREE_)
  }
  
  # Generate tree structure from the root
  x <- kids$id[1]
  TREE_ <- .gatherDescendands(kids, x)
  TREE <- paste0("(", TREE_, ":1,", x, ":1);")
  tr <- read.tree(text = TREE)  # Convert to tree object
  return(tr)
}

# Function to visualize the phylogenetic tree with group-based color coding
getPhylogeneticTree <- function(tr) {
  # Assign group labels based on tip labels
  group <- ifelse(grepl("seed", tr$tip.label, ignore.case = TRUE), "seeding", "harvest")
  label_data <- data.frame(
    label = tr$tip.label,
    group = factor(group, levels = c("seeding", "harvest"))
  )
  
  # Create and return the tree plot
  p <- ggtree(tr) %<+% label_data +
    geom_tiplab(aes(label = label, color = group), hjust = -0.2) +
    scale_color_manual(values = c("seeding" = "blue", "harvest" = "red")) +
    theme_minimal() +
    theme(legend.position = "right")
  return(p)
}

# UI definition
ui <- fluidPage(
  titlePanel("Seed, Harvest, and Phylogenetic Tree Functions"),
  sidebarLayout(
    sidebarPanel(
      # Seed/Harvest function input forms
      selectInput(
        "function_choice",
        "Choose Function:",
        choices = c("Seed" = "seed", "Harvest" = "harvest")
      ),
      conditionalPanel(
        condition = "input.function_choice === 'seed'",
        textInput("id", "ID", value = ""),
        textInput("from", "From", value = ""),
        numericInput("cellCount", "Cell Count", value = 0, min = 0),
        textInput("flask", "Flask", value = ""),
        textInput("tx", "Transaction Time (tx)", value = Sys.time()),
        textInput("media", "Media (required)", value = ""),
        checkboxInput("excludeOption", "Exclude Option", value = FALSE),
        checkboxInput("preprocessing", "Preprocessing", value = TRUE),
        textInput("param", "Additional Parameters (optional)", value = "")
      ),
      conditionalPanel(
        condition = "input.function_choice === 'harvest'",
        textInput("id_h", "ID", value = ""),
        textInput("from_h", "From", value = ""),
        numericInput("cellCount_h", "Cell Count", value = 0, min = 0),
        textInput("tx_h", "Transaction Time (tx)", value = Sys.time()),
        textInput("media_h", "Media (optional)", value = ""),
        checkboxInput("excludeOption_h", "Exclude Option", value = FALSE),
        checkboxInput("preprocessing_h", "Preprocessing", value = TRUE),
        textInput("param_h", "Additional Parameters (optional)", value = "")
      ),
      # Tree generation input
      textInput("tree_id", "Enter Tree ID", value = ""),
      actionButton("run", "Run Function"),
      actionButton("generate_tree", "Generate Phylogenetic Tree")
    ),
    mainPanel(
      # Outputs for tree and heatmap visualizations
      verbatimTextOutput("result"),
      plotOutput("phylo_tree", click = "tree_click"),
      plotOutput("heatmap_plot")
    )
  )
)

# Server logic
server <- function(input, output, session) {
  tree_data <- reactiveVal(NULL)  # Store the tree object
  
  observeEvent(input$generate_tree, {
    req(input$tree_id)  # Ensure a tree ID is provided
    tryCatch({
      tr <- getPedigreeTree(id = input$tree_id)  # Generate tree
      tree_data(tr)  # Save the tree object
      tree_plot <- getPhylogeneticTree(tr)  # Create tree plot
      output$phylo_tree <- renderPlot(tree_plot)  # Render the plot
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")  # Display errors
    })
  })
  
  observeEvent(input$tree_click, {
    req(input$tree_click, tree_data())  # Ensure tree data and click input are available
    tr <- tree_data()  # Retrieve the stored tree object
    
    # Map the clicked Y-coordinate to the node label
    tree_plot_data <- ggtree(tr)$data
    clicked_y <- round(input$tree_click$y)
    node_label <- tree_plot_data$label[tree_plot_data$y == clicked_y]
    
    # Debugging logs
    print(paste("Clicked node index:", clicked_y))
    print(paste("Clicked node label:", node_label))
    
    tryCatch({
      heatmap_data <- GenomePerspectiveView_Bulk(node_label)  # Generate heatmap
      output$heatmap_plot <- renderPlot({
        if ("ComplexHeatmap" %in% installed.packages()) {
          ComplexHeatmap::Heatmap(heatmap_data, name = node_label)
        } else {
          pheatmap::pheatmap(heatmap_data, main = node_label)
        }
      })
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")  # Display errors
    })
  })
  
  observeEvent(input$run, {
    # Run the selected function (Seed or Harvest) based on user input
    result <- tryCatch({
      if (input$function_choice == "seed") {
        if (input$media == "") stop("Media is required for seed function.")
        seed(
          id = input$id,
          from = input$from,
          cellCount = input$cellCount,
          flask = input$flask,
          tx = input$tx,
          media = input$media,
          excludeOption = input$excludeOption,
          preprocessing = input$preprocessing,
          param = if (input$param == "") NULL else input$param
        )
      } else {
        harvest(
          id = input$id_h,
          from = input$from_h,
          cellCount = input$cellCount_h,
          tx = input$tx_h,
          media = if (input$media_h == "") NULL else input$media_h,
          excludeOption = input$excludeOption_h,
          preprocessing = input$preprocessing_h,
          param = if (input$param_h == "") NULL else input$param_h
        )
      }
    }, error = function(e) {
      paste("Error:", e$message)  # Capture and display errors
    })
    output$result <- renderPrint(result)  # Display the result of the function
  })
}

# Launch the Shiny app
shinyApp(ui = ui, server = server)
