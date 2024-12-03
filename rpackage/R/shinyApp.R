# Script by Thomas Veith and Noemi Andor PhD
# Integrated back end for the CLONEID web portal
# Features: Phylogenetic Trees, Genomic Heatmaps, Seed/Harvest, and File Upload

# seed("TESTtommy_SNU-668_G2_A12_seed",from = "SNU-668_G2_A10_harvesT4",flask = 2,cellCount = NA,media = 8, preprocessing=F)

# Load required libraries
library(shiny)
library(DBI)
library(cloneid)
library(ggtree)
library(ggplot2)
library(matlab)
library(ape)
library(tools)
library(tiff)
library(grid)
library(shinyjqui)

# Helper function to execute database queries
executeQuery <- function(query) {
  mydb <- cloneid::connect2DB()
  on.exit(dbDisconnect(mydb), add = TRUE)
  tryCatch({
    message("Executing query: ", query)
    rs <- dbSendQuery(mydb, query)
    result <- dbFetch(rs)
    dbClearResult(rs)
    return(result)
  }, error = function(e) {
    message("Error executing query: ", e$message)
    stop(e)
  })
}

# Function to retrieve genomic perspective data
GenomePerspectiveView_Bulk <- function(id) {
  print(id)
  query <- paste0(
    "SELECT DISTINCT cloneID, parent 
     FROM Perspective 
     WHERE whichPerspective='GenomePerspective' 
     AND origin IN ('", id, "')"
  )
  origin <- executeQuery(query)
  if (nrow(origin) == 0) stop("No genomic data available for the provided ID.")
  x <- origin$cloneID[is.na(origin$parent)]
  p <- getSubProfiles(cloneID_or_sampleName = x, whichP = "GenomePerspective")
  return(p)
}

# Function to find clone IDs with genomic data
whichCLONEIDsHaveGenomePerspective <- function(tr){
  stmt = paste0("SELECT DISTINCT origin, whichPerspective FROM Perspective")
  mydb_new = cloneid::connect2DB()
  on.exit(dbDisconnect(mydb_new), add = TRUE)  # Ensure the connection is closed
  rs = suppressWarnings(dbSendQuery(mydb_new, stmt))
  ori = dbFetch(rs, n = -1)
  dbClearResult(rs)
  IDSwithGENOME = intersect(tr$tip.label, ori$origin[ori$whichPerspective == 'GenomePerspective'])
  return(IDSwithGENOME)
}

# Function to construct a phylogenetic tree
getPedigreeTree <- function(cellLine = NULL, id = NULL) {
  if (!is.null(id)) {
    kids <- findAllDescendandsOf(id)
  } else if (!is.null(cellLine)) {
    query <- paste0("SELECT * FROM Passaging WHERE cellLine = '", cellLine, "'")
    kids <- executeQuery(query)
  } else {
    stop("Either 'cellLine' or 'id' must be provided.")
  }
  if (nrow(kids) == 0) stop("No tree data available for the provided input.")
  kids <- kids[order(kids$date, kids$passage), ]
  rownames(kids) <- kids$id
  
  .gatherDescendands <- function(kids, x) {
    ii <- grep(paste0("^", x, "$"), kids$passaged_from_id1, ignore.case = TRUE)
    if (length(ii) == 0) return("")
    TREE_ <- "("
    for (i in ii) {
      y <- .gatherDescendands(kids, kids$id[i])
      if (nchar(y) > 0) y <- paste0(y, ":1,")
      TREE_ <- paste0(TREE_, y, kids$id[i], ":1,")
    }
    TREE_ <- gsub(",$", ")", TREE_)
    return(TREE_)
  }
  
  x <- kids$id[1]
  TREE_ <- .gatherDescendands(kids, x)
  TREE <- paste0("(", TREE_, ":1,", x, ":1);")
  tr <- read.tree(text = TREE)
  return(tr)
}

# Function to visualize the phylogenetic tree
getPhylogeneticTree <- function(tr) {
  group <- ifelse(grepl("seed", tr$tip.label, ignore.case = TRUE), "seeding", "harvest")
  label_data <- data.frame(
    label = tr$tip.label,
    group = factor(group, levels = c("seeding", "harvest"))
  )
  # Get IDs with genomic data
  IDSwithGENOME <- whichCLONEIDsHaveGenomePerspective(tr)
  
  # Add a column to indicate if the node has genomic data
  label_data$has_genomic_data <- ifelse(label_data$label %in% IDSwithGENOME, TRUE, FALSE)
  
  # Set an offset for labels
  label_offset <- 0.1  # Adjust the offset as needed
  
  # Create the tree plot with labels offset
  p <- ggtree(tr) %<+% label_data +
    geom_tiplab(aes(label = label, color = group), offset = label_offset) +
    scale_color_manual(values = c("seeding" = "blue", "harvest" = "red")) +
    theme_minimal() +
    theme(legend.position = "right")
  
  # Get the data frame from the plot
  tree_data <- p$data
  
  # Filter for tips (isTip == TRUE) and has genomic data
  genomic_nodes <- subset(tree_data, isTip & label %in% IDSwithGENOME)
  
  # The labels are drawn at x + offset
  genomic_nodes$label_x <- genomic_nodes$x + label_offset
  
  # Add forest green squares on top of the node names
  p <- p + geom_point(
    data = genomic_nodes,
    aes(x = label_x, y = y),
    color = "#228B22",  # Forest green color
    shape = 15,
    size = 3
  )
  
  # Return both the plot and the genomic_nodes data
  return(list(plot = p, genomic_nodes = genomic_nodes))
}


# UI setup
ui <- fluidPage(
  navbarPage(
    "CLONEID Portal",
    
    # Tab 1: Generate Phylogenetic Tree
    tabPanel(
      "View Data",
      sidebarLayout(
        sidebarPanel(
          textInput("tree_id", "Enter Tree ID"),
          actionButton("generate_tree", "Generate Phylogenetic Tree")
        ),
        mainPanel(
          jqui_resizable(
            plotOutput("phylo_tree", click = "tree_click"),
            options = list(maxWidth = 800, minWidth = 300, maxHeight = 600, minHeight = 300)
          ),
          uiOutput("heatmaps_ui") # Dynamically generate heatmaps
        )
      )
    ),
    
    # Tab 2: Run Function (Seed/Harvest)
    tabPanel(
      "Upload Phenotypic Data",
      sidebarLayout(
        sidebarPanel(
          selectInput(
            "function_choice",
            "Choose Function:",
            choices = c("Seed" = "seed", "Harvest" = "harvest")
          ),
          conditionalPanel(
            condition = "input.function_choice === 'seed'",
            textInput("id", "ID"),
            textInput("from", "From"),
            numericInput("cellCount", "Cell Count", value = 0, min = 0),
            textInput("flask", "Flask"),
            textInput("tx", "Transaction Time (tx)", value = Sys.time()),
            textInput("media", "Media (required)"),
            checkboxInput("excludeOption", "Exclude Option", FALSE),
            checkboxInput("preprocessing", "Preprocessing", TRUE),
            textInput("param", "Additional Parameters (optional)")
          ),
          conditionalPanel(
            condition = "input.function_choice === 'harvest'",
            textInput("id_h", "ID"),
            textInput("from_h", "From"),
            numericInput("cellCount_h", "Cell Count", value = 0, min = 0),
            textInput("tx_h", "Transaction Time (tx)", value = Sys.time()),
            textInput("media_h", "Media (optional)"),
            checkboxInput("excludeOption_h", "Exclude Option", FALSE),
            checkboxInput("preprocessing_h", "Preprocessing", TRUE),
            textInput("param_h", "Additional Parameters (optional)")
          ),
          actionButton("run", "Run Function")
        ),
        mainPanel(
          verbatimTextOutput("result"),
          plotOutput("tiff_images")
        )
      )
    ),
    
    # Tab 3: File Upload
    tabPanel(
      "Upload Genotypic Data",
      sidebarLayout(
        sidebarPanel(
          fileInput(
            "folder_upload",
            "Select ZIP folder or a file",
            multiple = TRUE,
            accept = c(".zip", ".spstats")
          ),
          actionButton("upload_btn", "Upload data to CLONEID")
        ),
        mainPanel(
          verbatimTextOutput("upload_status"),
          plotOutput("pie_chart")
        )
      )
    )
  )
)

# Server setup (unchanged, logic remains the same)
server <- function(input, output, session) {
  tree_data <- reactiveVal(NULL)           # Store the tree object
  genomic_nodes_data <- reactiveVal(NULL)  # Store genomic nodes data
  heatmaps_data <- reactiveValues(data = list())  # Store multiple heatmaps
  
  # Generate Tree
  observeEvent(input$generate_tree, {
    req(input$tree_id)
    
    # Clear existing outputs when generating a new tree
    output$phylo_tree <- renderPlot({
      plot(NA, xlim = c(0, 1), ylim = c(0, 1), type = "n", axes = FALSE, xlab = "", ylab = "")
      text(0.5, 0.5, "Generating new tree...", cex = 1.5, col = "blue")
    })
    
    tryCatch({
      tr <- getPedigreeTree(id = input$tree_id)
      result <- getPhylogeneticTree(tr)          # Get tree plot and genomic nodes
      tree_plot <- result$plot
      tree_data(tr)                              # Save the tree object
      genomic_nodes_data(result$genomic_nodes)   # Save genomic nodes data
      output$phylo_tree <- renderPlot(tree_plot) # Render the plot
      
      # Reset heatmaps when a new tree is generated
      heatmaps_data$data <- list()
      output$heatmaps_ui <- renderUI({
        plotOutput("heatmap_placeholder")
      })
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Handle Node Click to Add Heatmap
  observeEvent(input$tree_click, {
    req(input$tree_click, tree_data())
    tr <- tree_data()
    tree_plot_data <- ggtree(tr)$data
    clicked_y <- round(input$tree_click$y)
    node_label <- tree_plot_data$label[tree_plot_data$y == clicked_y]
    node_label <- node_label[1]
    
    tryCatch({
      heatmap_data <- GenomePerspectiveView_Bulk(node_label)
      
      # Append the new heatmap data
      heatmaps_data$data[[node_label]] <- heatmap_data
      
      # Dynamically render all heatmaps
      output$heatmaps_ui <- renderUI({
        lapply(names(heatmaps_data$data), function(label) {
          plotOutput(outputId = paste0("heatmap_", label))
        })
      })
      
      # Generate plots for each heatmap
      lapply(names(heatmaps_data$data), function(label) {
        output[[paste0("heatmap_", label)]] <- renderPlot({
          pheatmap::pheatmap(heatmaps_data$data[[label]], main = label)
        })
      })
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Run Function
  observeEvent(input$run, {
    tryCatch({
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
      paste("Error:", e$message)
    })
    
    # After seed or harvest, read and display PNG images
    vis_folder <- "~/Downloads/tmp/vis"
    png_files <- list.files(vis_folder, pattern = "\\.png$", full.names = TRUE, ignore.case = TRUE)
    if (length(png_files) > 0) {
      # Render subplots for the PNG images
      output$tiff_images <- renderPlot({
        # Read PNG files into a list
        png_list <- lapply(png_files, function(file) png::readPNG(file))
        
        # Determine grid layout
        n_rows <- 2
        n_cols <- ceiling(length(png_list) / n_rows)
        # Set up a plotting area with a grid
        par(mfrow = c(n_rows, n_cols), mar = c(1, 1, 2, 1))  # Reduce margins for better fit
        # Plot each image
        for (i in seq_along(png_list)) {
          img <- png_list[[i]]
          plot(NA, xlim = c(0, 1), ylim = c(0, 1), type = "n", axes = FALSE, xlab = "", ylab = "")
          rasterImage(img, 0, 0, 1, 1)  # Render the PNG image
          title(main = paste("Image", i), line = -1)  # Add a title for each image
        }
      })
    } else {
      output$tiff_images <- renderPlot({
        plot(NA, xlim = c(0, 1), ylim = c(0, 1), type = "n", axes = FALSE, xlab = "", ylab = "")
        text(0.5, 0.5, "No PNG images found in the directory.", cex = 1.5, col = "red")
      })
    }
    
  })
  
  # File Upload
  observeEvent(input$upload_btn, {
    req(input$folder_upload)
    uploaded_files <- input$folder_upload$datapath
    if (any(grepl("\\.zip$", uploaded_files))) {
      temp_dir <- tempdir()
      unzip(uploaded_files[1], exdir = temp_dir)
      spstats_files <- list.files(temp_dir, pattern = "\\.spstats$", full.names = TRUE)
      if (length(spstats_files) == 1) {
        tryCatch({
          viewPerspective(spstats_files[1], whichP = "GenomePerspective")
          output$upload_status <- renderText("File processed successfully.")
        }, error = function(e) {
          output$upload_status <- renderText(paste("Error:", e$message))
        })
        
        output$pie_chart <- renderPlot({
          tryCatch({
            # Extract the file name (without extension) using fileparts
            file_parts <- matlab::fileparts(spstats_files)
            sample_name <- file_parts$name  # Extract the base name without extension
            
            # Get subclones and their sizes
            sps <- getSubclones(cloneID_or_sampleName = sample_name, whichP = "GenomePerspective")
            clonesizes <- cloneid::getSPsize(names(sps))
            
            # Plot the pie chart
            pie(
              clonesizes,
              main = paste("Clonal composition in", sample_name),
              col = rainbow(length(clonesizes))  # Optional: Add colors
            )
          }, error = function(e) {
            showNotification(paste("Error in pie chart:", e$message), type = "error")
          })
        })
        
      } else {
        output$upload_status <- renderText("No valid .spstats file found.")
      }
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)


