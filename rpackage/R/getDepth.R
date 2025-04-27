getDepth <- function(id) {
  mydb_new = cloneid::connect2DB()
  kids = id
  depth = 0
  while (!isempty(kids)) {
    depth = depth + 1
    id = kids[1]
    stmt = paste0("select cloneID from Perspective where parent=", id);
    rs = suppressWarnings(dbSendQuery(mydb_new, stmt))
    kids = fetch(rs, n = -1)$cloneID
  }
  return(depth)
}

# ## UMAP visualization
# id = as.numeric(extractID(names(sps)[1]))
# if (getDepth(id) > 1) {
#   # ncol(p)>20){
#   col = rainbow(length(unique(clonemembership)))
#   names(col) = unique(clonemembership)
#   la = umap::umap(t(p))
#   plot(la$layout, pch = 20, col = col[clonemembership])
# } else {
#   gplots::heatmap.2(t(p))
#   ## @TODO: Not sure if this still works if p is a vector rather than a matrix -- would need to check to make sure there is no error
# }