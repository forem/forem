function getReactionsPath() {
  return (checkUserLoggedIn() ? "/reactions" : "/reactions/logged_out_reaction_counts")
}
