#' Get metadata for a Discogs user collection
#'
#' Return metadata for releases in a Discogs user collection.
#'
#' @param user_name The username of the collection you are trying to request.
#' @param folder_id The ID of the collection folder (default value is 0,
#' the “All” folder).
#' @param simplify_df Coerce list of results into a nested data frame object
#' @inheritParams discogs_artist
#'
#' @return a \code{discogs_collection} object that contains the extracted content from the request,
#' the original JSON response object and the request path.
#'
#' @export
#' @examples \dontrun{
#' discogs_user_collection(user_name = "rodneyfool")
#' discogs_user_collection(user_name = "rodneyfool", simplify_df = TRUE)
#' }
discogs_user_collection <- function(user_name, folder_id = 0, simplify_df = FALSE,
                                    access_token = discogs_api_token()) {

  # check for internet
  check_internet()

  # create path
  path <- glue(
    "users/{user_name}/collection/folders/{folder_id}/releases?sort=added&sort_order=desc"
    )

  # base API users URL
  url <- modify_url(base_url, path = path)

  # request API for user collection
  req <- discogs_get(
    url = url, ua,
    add_headers(Authorization = glue("Discogs token={access_token}")
                )
    )

  # break if user doesnt exist
  check_status(req)

  # break if object isnt json
  check_type(req)

  # extract request content
  data <- fromJSON(
    content(req, "text", encoding = "UTF-8"),
    simplifyVector = FALSE
    )

  # how many collection pages?
  pages <- data$pagination$pages

  # iterate through pages of collection
  collection <- lapply(seq_len(pages), function(x){

    # request collection page
    req <- discogs_get(
      url = paste0(url, "&page=", x), ua,
      add_headers(Authorization = glue("Discogs token={access_token}")
                  )
      )

    # break if user doesnt exist
    check_status(req)

    # break if object isnt json
    check_type(req)

    # extract request content
    if (simplify_df) {

      data <- fromJSON(
        content(req, "text", encoding = "UTF-8"),
        simplifyVector = TRUE, flatten = TRUE
        )

    } else {

      data <- fromJSON(
        content(req, "text", encoding = "UTF-8"),
        simplifyVector = FALSE
        )
    }

    # extract releases
    data <- data$releases

  })

  # combine pages
  if (simplify_df) {

    collection <- bind_rows(collection)

  } else {

    collection <- unlist(collection, recursive = FALSE)

    }

  # create s3 object
  structure(
    list(
      content = collection,
      path = path,
      response = req
    ),
    class = "discogs_collection"
  )
}
