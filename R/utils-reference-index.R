reference_index <- function(pkg = NULL, quarto_sub_folder = "", version_folder = "",
                            reference_folder = "", vignettes_folder, output = "qmd",
                            package_description = NULL) {
  
  if(is.character(pkg)) pkg <- pkgdown::as_pkgdown(pkg)
  
  ref_list <- reference_to_list_index(pkg)
  
  dir_out <- path("/", quarto_sub_folder, version_folder, reference_folder)
  
  ref_convert <- reference_index_convert(ref_list, dir_out)
  
  res <- purrr::imap(ref_convert, ~ {
    if(.y == 1 || .y == "NULL") {
      .x
    } else {
      if(length(.x)>2){
        c(" ", paste("##", .y), " ", .x) 
      } else {
        c(" ", paste("##", .y), " ") 
      }
    }
  })
  
  res <- reduce(res, c)
  
  if(output == "qmd") {
    if(is.null(package_description)) package_description <-  pkg$desc$get_field("Title")
    res <- c("---", 
             paste0("title: ", pkg$package), 
             paste0("description: ", package_description),
             "---", 
             res
    )
  }
  
  res
}

reference_index_convert <- function(index_list, dir_out = "") {
  out <- map(index_list, ~ map(.x, ~ {
    
    # Manual fixes of special characters in funs variable
    
    funcs <- .x$funs
    if(length(funcs) > 1) funcs <- .x$funs[[1]]
    if(length(funcs) == 0) funcs <- .x$alias
    funcs <- gsub("&lt;", "<", funcs)
    funcs <- gsub("&gt;", ">", funcs)
    
    
    desc <- .x$title
    c(
      paste0("[", funcs, "](", .x$file_out,")"),
      desc
    )
  }))
  header <- c("Function | Description", "|---|---|")
  map(out, ~ c(header, map_chr(.x, ~ paste0("|", .x[[1]], "|", .x[[2]], "|")) ))
}


reference_to_list_index <- function(pkg) {
  if(is.character(pkg)) pkg <- as_pkgdown(pkg)
  pkg_ref <- pkg$meta$reference
  
  pkg_topics <- pkg$topics
  topics_env <- match_env(pkg_topics)
  
  if (is.null(pkg_ref)) {
    x <- list(data.frame(contents = pkg_topics$name))
  }  else {
    x <- pkg_ref
  }
  
  sections_list <- map(
    seq_along(x),
    ~ {
      ref <- x[[.x]]
      topic_list <- map(
        ref$contents,
        ~ {
          item_numbers <- NULL
          try(
            item_numbers <- eval(parse(text = paste0("`", .x,"`")), topics_env), 
            silent = TRUE
          )
          if(is.null(item_numbers)) {
            item_numbers <- eval(parse(text = .x), topics_env)
          }
          item_numbers
        }
      )
      topic_ids <- as.numeric(flatten(topic_list))
      transpose(pkg_topics[topic_ids, ])
    })
  
  if(!is.null(pkg_ref)) {
    sections_title <- map(pkg_ref, ~c(.x$title, .x$subtitle))
    names(sections_list) <- sections_title
  }
  
  sections_list
}